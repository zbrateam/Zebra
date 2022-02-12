//
//  RootViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

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
			case .home:      return ZBHomeViewController()
			case .browse:    return ZBSourceListViewController()
			case .installed: return ZBPackageListViewController()
			case .me:        return ZBSettingsViewController()
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
	private var currentTab: AppTab?

	init() {
		super.init(style: .doubleColumn)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		#if targetEnvironment(macCatalyst)
		// Split view controller
		primaryBackgroundStyle = .sidebar
		preferredDisplayMode = .oneBesideSecondary
		preferredPrimaryColumnWidth = 220
		minimumPrimaryColumnWidth = 220
		maximumPrimaryColumnWidth = 220

		let sidebarViewController = MacSidebarViewController()
		navigationDelegate = sidebarViewController
		let sidebarNavigationController = UINavigationController(rootViewController: sidebarViewController)
		sidebarNavigationController.setNavigationBarHidden(true, animated: false)
		setViewController(sidebarNavigationController, for: .primary)

		let secondaryNavigationController = UINavigationController()
		secondaryNavigationController.delegate = self
		secondaryNavigationController.setNavigationBarHidden(true, animated: false)
		setViewController(secondaryNavigationController, for: .secondary)
		#else
		// Tab bar controller
		#endif

		view.addInteraction(UIDropInteraction(delegate: self))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		selectTab(.home)
	}

	// MARK: - Tabs

	func selectTab(_ tab: AppTab) {
		if tab == currentTab {
			// We’re already on this tab, just pop to root.
			#if targetEnvironment(macCatalyst)
			let navigationController = viewController(for: .secondary) as! UINavigationController
			#else
			let navigationController = tabBarController!.selectedViewController as! UINavigationController
			#endif
			navigationController.popToRootViewController(animated: true)
			return
		}

		currentTab = tab

		#if targetEnvironment(macCatalyst)
		// Update the secondary view controller’s stack
		let secondaryNavigationController = viewController(for: .secondary) as! UINavigationController
		secondaryNavigationController.viewControllers = [tab.viewController]
		#else
		// Select tab bar item
		#endif

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

	// MARK: - Application Menu

	@IBAction func openAbout() {
		// TODO: This
	}

	@IBAction func openPreferences() {
		// TODO: This
	}

	// MARK: - File Menu

	@IBAction func openPackage() {
		// TODO: This
		let viewController: UIDocumentPickerViewController
		if #available(iOS 14, *) {
			viewController = UIDocumentPickerViewController(forOpeningContentTypes: [ .package ])
		} else {
			viewController = UIDocumentPickerViewController(documentTypes: [ UTType.package.identifier ], in: .import)
		}
//		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
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
		// TODO: This
		let viewController: UIDocumentPickerViewController
		if #available(iOS 14, *) {
			viewController = UIDocumentPickerViewController(forOpeningContentTypes: [ .sourcesList, .sourcesFile ])
		} else {
			viewController = UIDocumentPickerViewController(documentTypes: [ UTType.sourcesList.identifier, UTType.sourcesFile.identifier ], in: .import)
		}
//		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
	}

	@IBAction func exportSources() {
		// TODO: This
		let viewController: UIDocumentPickerViewController
		if #available(iOS 14, *) {
			viewController = UIDocumentPickerViewController(forExporting: [])
		} else {
			viewController = UIDocumentPickerViewController(urls: [], in: .moveToService)
		}
//		viewController.delegate = self
		present(viewController, animated: true, completion: nil)
	}

	@IBAction func refreshSources() {
		// TODO: This
	}

	@IBAction func addSource() {
		// TODO: This
	}

}

#if targetEnvironment(macCatalyst)
extension RootViewController: UINavigationControllerDelegate {

	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		let windowScene = view.window!.windowScene!
		let sceneDelegate = windowScene.delegate as! AppSceneDelegate
		windowScene.title = viewController.title

		let isRoot = navigationController.viewControllers.first == viewController
		sceneDelegate.toolbarItems = [
			isRoot ? .flexibleSpace : .back
		]
	}

}
#endif

extension RootViewController: UIDropInteractionDelegate {

	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		let types = FileImportController.supportedTypes.map { item in item.identifier }
		return session.items.count == 1 && session.hasItemsConforming(toTypeIdentifiers: types)
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}

	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		guard let item = session.items.first else {
			return
		}

		Task(priority: .userInitiated) {
			// TODO: Handle error
			try! await FileImportController.handleFile(itemProvider: item.itemProvider)
		}
	}

}
