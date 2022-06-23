//
//  RootViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import Plains

protocol RootViewControllerDelegate: AnyObject {
	func selectTab(_ tab: RootViewController.AppTab)
}

class RootViewController: UISplitViewController {

	enum AppTab: Int, CaseIterable {
		case home, browse, installed, me

		var name: String {
			switch self {
			case .home:      return .localize("Home")
			case .browse:    return .localize("Browse")
			case .installed: return .localize("Installed")
			case .me:        return .localize("Me")
			}
		}

		var icon: UIImage? {
			switch self {
			case .home:      return UIImage(systemName: "house.fill")
			case .browse:    return UIImage(systemName: "circle.grid.2x2.fill")
			case .installed: return UIImage(systemName: "arrow.down.app.fill")
			case .me:        return UIImage(systemName: "person.crop.circle.fill")
			}
		}

		var viewController: UIViewController {
			switch self {
			case .home:      return HomeViewController()
			case .browse:    return BrowseViewController()
			case .installed: return PackageListViewController(filter: .installed)
			case .me:        return UIViewController() // ZBSettingsViewController()
			}
		}
	}

	static let tabKeyCommands: [UIKeyCommand] = {
		var result = [UIKeyCommand]()
		for (i, row) in AppTab.allCases.enumerated() {
			result.append(UIKeyCommand(title: row.name,
																 image: row.icon,
																 action: #selector(switchToTab),
																 input: "\(i + 1)",
																 modifierFlags: .command,
																 propertyList: i,
																 state: .off))
		}
		return result
	}()

	private weak var navigationDelegate: RootViewControllerDelegate?
	private var realTabBarController: UITabBarController!

	init() {
		super.init(style: .doubleColumn)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		// Split view controller
		primaryBackgroundStyle = .sidebar
		preferredDisplayMode = .oneBesideSecondary
		preferredSplitBehavior = .tile

		#if targetEnvironment(macCatalyst)
		let sidebarWidth: Double = 220
		#else
		let sidebarWidth: Double = 240
		#endif

		preferredPrimaryColumnWidth = sidebarWidth
		minimumPrimaryColumnWidth = sidebarWidth
		maximumPrimaryColumnWidth = sidebarWidth

		let sidebarViewController = SidebarViewController()
		navigationDelegate = sidebarViewController

		let sidebarNavigationController = NavigationController(rootViewController: sidebarViewController)
		#if targetEnvironment(macCatalyst)
		sidebarNavigationController.setNavigationBarHidden(true, animated: false)
		#endif
		setViewController(sidebarNavigationController, for: .primary)

		realTabBarController = UITabBarController()
		realTabBarController.delegate = self
		realTabBarController.viewControllers = AppTab.allCases.map { item in
			let viewController = NavigationController(rootViewController: item.viewController)
			viewController.delegate = self
			viewController.tabBarItem = UITabBarItem(title: item.name, image: item.icon, selectedImage: nil)
			#if targetEnvironment(macCatalyst)
			viewController.setNavigationBarHidden(true, animated: false)
			#else
			viewController.navigationBar.prefersLargeTitles = true
			#endif
			return viewController
		}
		setViewController(realTabBarController, for: .secondary)
		setViewController(realTabBarController, for: .compact)

		view.addInteraction(UIDropInteraction(delegate: self))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(self.updateUpdates), name: PackageManager.databaseDidRefreshNotification, object: nil)

		updateLayout()
		selectTab(.home)
		updateUpdates()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: PackageManager.databaseDidRefreshNotification, object: nil)
	}

	@objc private func updateUpdates() {
		let count = PackageManager.shared.updates.count

		DispatchQueue.main.async {
			let viewController = self.realTabBarController.viewControllers![AppTab.installed.rawValue]
			viewController.tabBarItem.badgeValue = count == 0 ? nil : NumberFormatter.localizedString(from: count as NSNumber, number: .none)
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		updateLayout()
	}

	private func updateLayout() {
		switch traitCollection.horizontalSizeClass {
		case .regular:
			realTabBarController?.tabBar.isHidden = true

		case .compact, .unspecified:
			realTabBarController?.tabBar.isHidden = false

		@unknown default:
			fatalError()
		}
	}

	// MARK: - Tabs

	var currentTab: AppTab { AppTab(rawValue: realTabBarController.selectedIndex)! }

	func selectTab(_ tab: AppTab) {
		if tab == currentTab {
			// We’re already on this tab, just pop to root.
			let navigationController = realTabBarController.selectedViewController as! UINavigationController
			navigationController.popToRootViewController(animated: true)
			return
		}

		// Select tab bar item
		realTabBarController.selectedIndex = tab.rawValue

		updateTabBar()
	}

	private func updateTabBar() {
		let tab = currentTab

		// Update UI
		navigationDelegate?.selectTab(tab)

		// Update menu bar state
		for item in RootViewController.tabKeyCommands {
			let tab2 = AppTab(rawValue: item.propertyList as! Int)!
			item.state = tab2 == tab ? .on : .off
		}

		// TODO: Can I, like, not rebuild the entire menu bar every time?
		UIMenuSystem.main.setNeedsRebuild()
	}

	// MARK: - Toolbar

	#if targetEnvironment(macCatalyst)
	@IBAction func goBack() {
		let secondaryNavigationController = realTabBarController.selectedViewController as! UINavigationController
		secondaryNavigationController.popViewController(animated: true)
	}
	#endif

	// MARK: - Application Menu

	@IBAction func openAbout() {
		// TODO: This
	}

	@IBAction func openPreferences() {
		// TODO: This
	}

	// MARK: - File Menu

	@IBAction func openPackage() {
		showOpenPicker(types: FileImportController.packageTypes)
	}

	// MARK: - View Menu

	@IBAction func openSearch() {
		// TODO: This
	}

	@IBAction func switchToTab(_ sender: UIKeyCommand) {
		let tab = AppTab(rawValue: sender.propertyList as! Int)!
		selectTab(tab)
	}

	// MARK: - Sources Menu

	@IBAction func importSources() {
		showOpenPicker(types: FileImportController.sourcesTypes)
	}

	@IBAction func exportSources() {
		guard let sourcesURL = PlainsConfig.shared.fileURL(forKey: "Plains::SourcesList"),
					(try? sourcesURL.checkResourceIsReachable()) == true else {
			return
		}
		showSavePicker(url: sourcesURL)
	}

	@IBAction func refreshSources() {
		SourceRefreshController.shared.refresh()
	}

	@IBAction func addSource() {
		// TODO: This
	}

	// MARK: - Files

	private func showOpenPicker(types: [UTType]) {
		let viewController = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
	}

	private func showSavePicker(url: URL) {
		let viewController = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
		present(viewController, animated: true, completion: nil)
	}

	private func handleOpenFile(itemProvider: NSItemProvider, filename: String? = nil) {
		Task(priority: .userInitiated) {
			do {
				try await FileImportController.handleFile(itemProvider: itemProvider, filename: filename)
			} catch {
				await MainActor.run {
					self.displayErrorDialog(title: .localize("Couldn’t open the file because an error occurred."),
																	error: error)
				}
			}
		}
	}

	private func displayErrorDialog(title: String, message: String? = nil, error: Error) {
		let body = [error.localizedDescription, (error as NSError).localizedRecoverySuggestion ?? "", message ?? ""]
			.filter { item in !item.isEmpty }
			.joined(separator: "\n\n")

		let alertController = UIAlertController(title: title,
																						message: body.isEmpty ? nil : body,
																						preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: .ok, style: .cancel))
		present(alertController, animated: true)
	}

}

extension RootViewController: UITabBarControllerDelegate {

	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		updateTabBar()
	}

}

extension RootViewController: UINavigationControllerDelegate {

	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		let windowScene = view.window!.windowScene!
		let sceneDelegate = windowScene.delegate as! AppSceneDelegate
		windowScene.title = viewController.title

		#if targetEnvironment(macCatalyst)
		let isRoot = navigationController.viewControllers.first == viewController
		sceneDelegate.toolbarItems = [
			isRoot ? .flexibleSpace : .back
		]
		#endif
	}

}

extension RootViewController: UIDropInteractionDelegate {

	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		if session.items.count == 1,
			 let item = session.items.first,
			 FileImportController.isSupportedType(itemProvider: item.itemProvider) {
			return true
		}
		return false
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		if let item = session.items.first,
			 FileImportController.isSupportedType(itemProvider: item.itemProvider) {
			return UIDropProposal(operation: .copy)
		}
		return UIDropProposal(operation: .cancel)
	}

	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		guard let item = session.items.first,
					FileImportController.isSupportedType(itemProvider: item.itemProvider) else {
			return
		}
		handleOpenFile(itemProvider: item.itemProvider)
	}

}

extension RootViewController: UIDocumentPickerDelegate {

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let url = urls.first,
			 let itemProvider = NSItemProvider(contentsOf: url),
			 FileImportController.isSupportedType(itemProvider: itemProvider) else {
			return
		}
		handleOpenFile(itemProvider: itemProvider, filename: url.lastPathComponent)
	}

}
