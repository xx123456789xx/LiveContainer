//
//  LCDataManagementView.swift
//  LiveContainer
//
//  Created by s s on 2025/4/18.
//

import SwiftUI

struct LCFolderPath {
    var path : URL
    var desc : String
}

struct LCDataManagementView : View {
    @State var folderPaths : [LCFolderPath]
    @State var filzaInstalled = false
    @State var appeared = false
    
    @StateObject private var appFolderRemovalAlert = YesNoHelper()
    @State private var folderRemoveCount = 0
    
    @StateObject private var keyChainRemovalAlert = YesNoHelper()
    @StateObject private var tmpRemovalAlert = YesNoHelper()
    @StateObject private var cacheRemovalAlert = YesNoHelper()
    @StateObject private var writeNamesAlert = YesNoHelper()
    @StateObject private var restoreNamesAlert = YesNoHelper()
    @StateObject private var deepCleanAlert = YesNoHelper()
    
    @AppStorage("LCShowAppNameForContainers") private var showAppNameForContainers = true 

    
    @State var errorShow = false
    @State var errorInfo = ""
    @State var successShow = false
    @State var successInfo = ""
    
    @EnvironmentObject private var sharedModel : SharedModel
    
    init() {
        _folderPaths = State(initialValue: [
            LCFolderPath(path: LCPath.docPath, desc: "Private Container"),
            LCFolderPath(path: LCPath.lcGroupDocPath, desc: "App Group Container"),
            LCFolderPath(path: Bundle.main.bundleURL, desc: "LiveContainer Bundle"),
        ])
    }
    
    var body: some View {
    
        Form {
            Section {
                if sharedModel.multiLCStatus != 2 {
                    Button {
                        moveAppGroupFolderFromPrivateToAppGroup()
                    } label: {
                        Text("lc.settings.appGroupPrivateToShare".loc)
                    }
                    Button {
                        moveAppGroupFolderFromAppGroupToPrivate()
                    } label: {
                        Text("lc.settings.appGroupShareToPrivate".loc)
                    }

                    Button {
                        Task { await moveDanglingFolders() }
                    } label: {
                        Text("lc.settings.moveDanglingFolderOut".loc)
                    }
                    Button(role:.destructive) {
                        Task { await cleanUpUnusedFolders() }
                    } label: {
                        Text("lc.settings.cleanDataFolder".loc)
                    }
                }

                Button(role:.destructive) {
                    Task { await removeKeyChain() }
                } label: {
                    Text("lc.settings.cleanKeychain".loc)
                }

                Button(role:.destructive) {
                    Task { await clearTemporaryFiles() }
                } label: {
                    Text("lc.settings.cleanTmp".loc)
                }
                
                Button(role:.destructive) {
                    Task { await clearCacheFiles() }
                } label: {
                    Text("lc.settings.cleanCaches".loc) 
                }

            }
            
            Section {
                Button {
                    Task { await clearIconCache() }
                } label: {
                    Text("lc.settings.clearIconCache".loc)
                }
            }
            
            Section {
                Toggle("lc.dataManagement.showAppNameForContainers".loc, isOn: $showAppNameForContainers)
                
                Button {
                    Task { await writeAppNamesToContainers() }
                } label: {
                    Text("lc.dataManagement.writeAppNames".loc)
                }
                
                Button {
                    Task { await restoreContainerNames() }
                } label: {
                    Text("lc.dataManagement.restoreAppNames".loc)
                }
                
                Button(role:.destructive) {
                    Task { await deepClean() }
                } label: {
                    Text("lc.dataManagement.deepClean".loc)
                }
            } header: {
                Text("lc.dataManagement.containerNames".loc)
            } footer: {
                Text("lc.dataManagement.containerNamesDesc".loc)
            }
            
            Section {
                ForEach(folderPaths, id:\.desc) { path in
                    HStack(spacing: 10) {
                        Text(path.desc)
                        Spacer()
                        if filzaInstalled {
                            Button {
                                openInFilza(path: path.path)
                            } label: {
                                Text("Filza")
                            }
                            .buttonStyle(.bordered)
                        }
                        Button {
                            copy(text: path.path.path)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("lc.settings.dataManagement".loc)
        .navigationBarTitleDisplayMode(.inline)
        .alert("lc.common.error".loc, isPresented: $errorShow){
        } message: {
            Text(errorInfo)
        }
        .alert("lc.common.success".loc, isPresented: $successShow){
        } message: {
            Text(successInfo)
        }
        .alert("lc.settings.cleanDataFolder".loc, isPresented: $appFolderRemovalAlert.show) {
            if folderRemoveCount > 0 {
                Button(role: .destructive) {
                    appFolderRemovalAlert.close(result: true)
                } label: {
                    Text("lc.common.delete".loc)
                }
            }

            Button("lc.common.cancel".loc, role: .cancel) {
                appFolderRemovalAlert.close(result: false)
            }
        } message: {
            if folderRemoveCount > 0 {
                Text("lc.settings.cleanDataFolderConfirm %lld".localizeWithFormat(folderRemoveCount))
            } else {
                Text("lc.settings.noDataFolderToClean".loc)
            }

        }
        .alert("lc.settings.cleanKeychain".loc, isPresented: $keyChainRemovalAlert.show) {
            Button(role: .destructive) {
                keyChainRemovalAlert.close(result: true)
            } label: {
                Text("lc.common.delete".loc)
            }

            Button("lc.common.cancel".loc, role: .cancel) {
                keyChainRemovalAlert.close(result: false)
            }
        } message: {
            Text("lc.settings.cleanKeychainDesc".loc)
        }
        .alert("lc.settings.cleanTmp".loc, isPresented: $tmpRemovalAlert.show) {
            Button(role: .destructive) {
                tmpRemovalAlert.close(result: true)
            } label: {
                Text("lc.common.delete".loc)
            }

            Button("lc.common.cancel".loc, role: .cancel) {
                tmpRemovalAlert.close(result: false)
            }
        } message: {
            Text("lc.settings.cleanTmpConfirm".loc)
        }
        .alert("lc.settings.cleanCaches".loc, isPresented: $cacheRemovalAlert.show) {
    Button(role: .destructive) {
        cacheRemovalAlert.close(result: true)
    } label: {
        Text("lc.common.delete".loc)
    }

    Button("lc.common.cancel".loc, role: .cancel) {
        cacheRemovalAlert.close(result: false)
    }
} message: {
    Text("lc.settings.cleanCacheConfirm".loc) 
}

        .alert("lc.dataManagement.writeAppNames".loc, isPresented: $writeNamesAlert.show) {
            Button {
                writeNamesAlert.close(result: true)
            } label: {
                Text("lc.dataManagement.writeAppNames".loc)
            }
            
            Button("lc.common.cancel".loc, role: .cancel) {
                writeNamesAlert.close(result: false)
            }
        } message: {
            Text("lc.dataManagement.writeAppNamesDesc".loc)
        }
        .alert("lc.dataManagement.restoreAppNames".loc, isPresented: $restoreNamesAlert.show) {
            Button {
                restoreNamesAlert.close(result: true)
            } label: {
                Text("lc.dataManagement.restoreAppNames".loc)
            }
            
            Button("lc.common.cancel".loc, role: .cancel) {
                restoreNamesAlert.close(result: false)
            }
        } message: {
            Text("lc.dataManagement.restoreAppNamesDesc".loc)
        }
        .alert("lc.dataManagement.deepClean".loc, isPresented: $deepCleanAlert.show) {
            Button(role: .destructive) {
                deepCleanAlert.close(result: true)
            } label: {
                Text("lc.common.delete".loc)
            }
            
            Button("lc.common.cancel".loc, role: .cancel) {
                deepCleanAlert.close(result: false)
            }
        } message: {
            Text("lc.dataManagement.deepCleanDesc".loc)
        }

        .onAppear {
            onAppearFunc()
        }
    }
    
    func onAppearFunc() {
        if !appeared {
            for app in sharedModel.apps {
                if app.appInfo.bundleIdentifier() == "com.tigisoftware.Filza" {
                    filzaInstalled = true
                    break
                }
            }
            appeared = true
        }
    }
    
    func writeAppNamesToContainers() async {
        guard let result = await writeNamesAlert.open(), result else {
            return
        }
        let count = LCContainer.bulkWriteAppNames(apps: sharedModel.apps + sharedModel.hiddenApps)
        successInfo = "lc.dataManagement.writeAppNamesDone %lld".localizeWithFormat(count)
        successShow = true
    }
    
    func restoreContainerNames() async {
        guard let result = await restoreNamesAlert.open(), result else {
            return
        }
        let count = LCContainer.bulkRestoreAppNames(apps: sharedModel.apps + sharedModel.hiddenApps)
        successInfo = "lc.dataManagement.restoreAppNamesDone %lld".localizeWithFormat(count)
        successShow = true
    }
    
    static func deepCleanFolderSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey], options: [], errorHandler: nil) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey])
            if values?.isRegularFile == true {
                total += Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
            }
        }
        return total
    }
    
    static func deepCleanIsHostAppPayload(_ url: URL) -> Bool {
        let infoPlistURL = url.appendingPathComponent("App.app/Info.plist")
        guard let info = NSDictionary(contentsOf: infoPlistURL) else {
            return false
        }
        return info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier
    }

    static func deepCleanIsHostResignedIPA(_ url: URL) -> Bool {
        let baseName = url.deletingPathExtension().lastPathComponent
        let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String
        let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        return baseName == bundleName || baseName == displayName
    }

    // Deep clean: orphan data folders in both the private and the shared location
    // (with their keychains), plus SideStore's payload copies and resigned-IPA exports.
    // Registered containers, installed apps, accounts and AppGroup data are never touched.
    func deepClean() async {
        guard let result = await deepCleanAlert.open(), result else {
            return
        }
        let fm = FileManager.default
        var registered = Set<String>()
        for app in sharedModel.apps + sharedModel.hiddenApps {
            for container in app.appInfo.containers {
                registered.insert(container.folderName)
            }
        }
        var freed: Int64 = 0
        for root in [LCPath.dataPath, LCPath.lcGroupDataPath] {
            let entries = (try? fm.contentsOfDirectory(atPath: root.path)) ?? []
            for entry in entries where !registered.contains(entry) {
                let url = root.appendingPathComponent(entry)
                var isDirectory: ObjCBool = false
                guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    continue
                }
                freed += Self.deepCleanFolderSize(at: url)
                try? fm.removeItem(at: url)
                LCUtils.removeAppKeychain(dataUUID: entry)
                sharedModel.appDataFolderNames.removeAll { $0 == entry }
            }
        }
        // SideStore's resigned-IPA exports. LiveContainer's own export is kept: it can
        // serve as a source when SideStore renews LiveContainer itself.
        let resignedDir = LCPath.docPath.appendingPathComponent("ResignedApps")
        let resignedItems = (try? fm.contentsOfDirectory(at: resignedDir, includingPropertiesForKeys: nil)) ?? []
        for item in resignedItems {
            if Self.deepCleanIsHostResignedIPA(item) {
                continue
            }
            freed += Self.deepCleanFolderSize(at: item)
            try? fm.removeItem(at: item)
        }
        // SideStore's payload copies. LiveContainer's own copy is always kept for the
        // same reason: SideStore re-signs LiveContainer from it at renewal time.
        var payloadDirs = [
            LCPath.lcGroupDocPath.deletingLastPathComponent().appendingPathComponent("Apps/Payloads")
        ]
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            payloadDirs.append(appSupport.appendingPathComponent("Apps/Payloads"))
        }
        for dir in payloadDirs {
            let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
            for item in items {
                if Self.deepCleanIsHostAppPayload(item) {
                    continue
                }
                freed += Self.deepCleanFolderSize(at: item)
                try? fm.removeItem(at: item)
            }
        }
        successInfo = "lc.dataManagement.deepCleanDone %@".localizeWithFormat(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))
        successShow = true
    }
    
    func cleanUpUnusedFolders() async {
        
        var folderNameToAppDict : [String:LCAppModel] = [:]
        for app in sharedModel.apps {
            for container in app.appInfo.containers {
                folderNameToAppDict[container.folderName] = app;
            }
        }
        for app in sharedModel.hiddenApps {
            for container in app.appInfo.containers {
                folderNameToAppDict[container.folderName] = app;
            }
        }
        
        var foldersToDelete : [String]  = []
        for appDataFolderName in sharedModel.appDataFolderNames {
            if folderNameToAppDict[appDataFolderName] == nil {
                foldersToDelete.append(appDataFolderName)
            }
        }
        folderRemoveCount = foldersToDelete.count
        
        guard let result = await appFolderRemovalAlert.open(), result else {
            return
        }
        do {
            let fm = FileManager()
            for folder in foldersToDelete {
                try fm.removeItem(at: LCPath.dataPath.appendingPathComponent(folder))
                LCUtils.removeAppKeychain(dataUUID: folder)
                sharedModel.appDataFolderNames.removeAll(where: { s in
                    return s == folder
                })
            }
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
        
    }
    
    func removeKeyChain() async {
        guard let result = await keyChainRemovalAlert.open(), result else {
            return
        }
        
        [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity].forEach {
          let status = SecItemDelete([
            kSecClass: $0,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
          ] as CFDictionary)
          if status != errSecSuccess && status != errSecItemNotFound {
              //Error while removing class $0
              errorInfo = status.description
              errorShow = true
          }
        }
    }

    func clearTemporaryFiles() async {
        guard let result = await tmpRemovalAlert.open(), result else {
            return
        }

        let fm = FileManager.default
        let tmpDirectory = fm.temporaryDirectory

        do {
            let tmpItems = try fm.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: nil)

            if tmpItems.isEmpty {
                successInfo = "lc.settings.noTmpToClean".loc
                successShow = true
                return
            }

            for item in tmpItems {
                try fm.removeItem(at: item)
            }

            successInfo = "lc.settings.cleanTmpComplete".loc
            successShow = true
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
    }

    func clearCacheFiles() async {
        guard let result = await cacheRemovalAlert.open(), result else {
            return
        }

        let fm = FileManager.default

        var allApps = sharedModel.apps + sharedModel.hiddenApps
        if UserDefaults.sideStoreExist() {
            allApps.append(LCAppModel(appInfo: BuiltInSideStoreAppInfo.shared))
        }
        
        var cleanedCount = 0

        do {
            for app in allApps {
                for container in app.uiContainers {
                    let containerPath = container.containerURL
                    let guestCachePath = containerPath.appendingPathComponent("Library/Caches")
                    
                    if fm.fileExists(atPath: guestCachePath.path) {
                        let cacheItems = try fm.contentsOfDirectory(at: guestCachePath, includingPropertiesForKeys: nil)
                        for item in cacheItems {
                            try fm.removeItem(at: item)
                        }
                        cleanedCount += 1
                    }
                }
            }
            if let lcCaches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
                fm.fileExists(atPath: lcCaches.path) {
                let cacheItems = try fm.contentsOfDirectory(at: lcCaches, includingPropertiesForKeys: nil)
                for item in cacheItems {
                    try fm.removeItem(at: item)
                }
                cleanedCount += 1
            }

            if cleanedCount == 0 {
                successInfo = "lc.settings.noCacheToClean".loc
            } else {
                successInfo = "lc.settings.cleanCacheComplete".loc
            }
            successShow = true
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
    }


    func moveDanglingFolders() async {
        let fm = FileManager()
        do {
            var appDataFoldersInUse : Set<String> = Set();
            var tweakFoldersInUse : Set<String> = Set();
            for app in sharedModel.apps {
                if !app.appInfo.isShared {
                    continue
                }
                for container in app.appInfo.containers {
                    appDataFoldersInUse.update(with: container.folderName);
                }

                
                if let folder = app.appInfo.tweakFolder {
                    tweakFoldersInUse.update(with: folder);
                }

            }
            
            for app in sharedModel.hiddenApps {
                if !app.appInfo.isShared {
                    continue
                }
                for container in app.appInfo.containers {
                    appDataFoldersInUse.update(with: container.folderName);
                }
                if let folder = app.appInfo.tweakFolder {
                    tweakFoldersInUse.update(with: folder);
                }

            }
            
            var movedDataFolderCount = 0
            let sharedDataFolders = try fm.contentsOfDirectory(atPath: LCPath.lcGroupDataPath.path)
            for sharedDataFolder in sharedDataFolders {
                if appDataFoldersInUse.contains(sharedDataFolder) {
                    continue
                }
                try fm.moveItem(at: LCPath.lcGroupDataPath.appendingPathComponent(sharedDataFolder), to: LCPath.dataPath.appendingPathComponent(sharedDataFolder))
                movedDataFolderCount += 1
            }
            
            var movedTweakFolderCount = 0
            let sharedTweakFolders = try fm.contentsOfDirectory(atPath: LCPath.lcGroupTweakPath.path)
            for tweakFolderInUse in sharedTweakFolders {
                if tweakFoldersInUse.contains(tweakFolderInUse) || tweakFolderInUse == "TweakLoader.dylib" {
                    continue
                }
                try fm.moveItem(at: LCPath.lcGroupTweakPath.appendingPathComponent(tweakFolderInUse), to: LCPath.tweakPath.appendingPathComponent(tweakFolderInUse))
                movedTweakFolderCount += 1
            }
            successInfo = "lc.settings.moveDanglingFolderComplete %lld %lld".localizeWithFormat(movedDataFolderCount,movedTweakFolderCount)
            successShow = true
            
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
    }
    
    func moveAppGroupFolderFromAppGroupToPrivate() {
        let fm = FileManager()
        do {
            if !fm.fileExists(atPath: LCPath.appGroupPath.path) {
                try fm.createDirectory(atPath: LCPath.appGroupPath.path, withIntermediateDirectories: true)
            }
            if !fm.fileExists(atPath: LCPath.lcGroupAppGroupPath.path) {
                try fm.createDirectory(atPath: LCPath.lcGroupAppGroupPath.path, withIntermediateDirectories: true)
            }
            
            let privateFolderContents = try fm.contentsOfDirectory(at: LCPath.appGroupPath, includingPropertiesForKeys: nil)
            let sharedFolderContents = try fm.contentsOfDirectory(at: LCPath.lcGroupAppGroupPath, includingPropertiesForKeys: nil)
            if privateFolderContents.count > 0 {
                errorInfo = "lc.settings.appGroupExistPrivate".loc
                errorShow = true
                return
            }
            for file in sharedFolderContents {
                try fm.moveItem(at: file, to: LCPath.appGroupPath.appendingPathComponent(file.lastPathComponent))
            }
            successInfo = "lc.settings.appGroup.moveSuccess".loc
            successShow = true
            
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
    }
    
    func moveAppGroupFolderFromPrivateToAppGroup() {
        let fm = FileManager()
        do {
            if !fm.fileExists(atPath: LCPath.appGroupPath.path) {
                try fm.createDirectory(atPath: LCPath.appGroupPath.path, withIntermediateDirectories: true)
            }
            if !fm.fileExists(atPath: LCPath.lcGroupAppGroupPath.path) {
                try fm.createDirectory(atPath: LCPath.lcGroupAppGroupPath.path, withIntermediateDirectories: true)
            }
            
            let privateFolderContents = try fm.contentsOfDirectory(at: LCPath.appGroupPath, includingPropertiesForKeys: nil)
            let sharedFolderContents = try fm.contentsOfDirectory(at: LCPath.lcGroupAppGroupPath, includingPropertiesForKeys: nil)
            if sharedFolderContents.count > 0 {
                errorInfo = "lc.settings.appGroupExist Shared".loc
                errorShow = true
                return
            }
            for file in privateFolderContents {
                try fm.moveItem(at: file, to: LCPath.lcGroupAppGroupPath.appendingPathComponent(file.lastPathComponent))
            }
            successInfo = "lc.settings.appGroup.moveSuccess".loc
            successShow = true
            
        } catch {
            errorInfo = error.localizedDescription
            errorShow = true
        }
    }
    
    func copy(text: String) {
        UIPasteboard.general.string = text
    }
    
    func openInFilza(path: URL) {
        let launchURLStr = "filza://view\(path.path)/."
        Task {
            do {
                try await sharedModel.apps.first(where: { app in
                    return app.appInfo.bundleIdentifier() == "com.tigisoftware.Filza"
                })?.runApp(urlStr: launchURLStr)
            } catch {
                successInfo = error.localizedDescription
                successShow = true
            }
        }
    }
    
    func clearIconCache() async {
        for app in sharedModel.apps {
            app.appInfo.clearIconCache()
        }
    }

}
