//
//  RootViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

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
	}

	static let tabKeyCommands: [UIKeyCommand] = {
		var result = [UIKeyCommand]()
		for (i, row) in AppTab.allCases.enumerated() {
			result.append(UIKeyCommand(title: row.name,
																 image: row.icon,
																 action: #selector(MacSidebarViewController.switchToTab),
																 input: "\(i + 1)",
																 modifierFlags: .command,
																 propertyList: i,
																 state: .off))
		}
		return result
	}()

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

		let sidebarNavigationController = UINavigationController(rootViewController: MacSidebarViewController())
		sidebarNavigationController.setNavigationBarHidden(true, animated: false)

		setViewController(sidebarNavigationController, for: .primary)
		setViewController(UINavigationController(rootViewController: UIViewController()), for: .secondary)
		#else
		// Tab bar controller
		#endif

		view.addInteraction(UIDropInteraction(delegate: self))
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

extension RootViewController: UIDropInteractionDelegate {

	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		let types = FileImportController.supportedTypes.map { item in item.identifier }
		return session.items.count == 1 && session.hasItemsConforming(toTypeIdentifiers: types)
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}

	@objc func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		guard let item = session.items.first else {
			return
		}

		Task(priority: .userInitiated) {
			// TODO: Handle error
			try! await FileImportController.handleFile(itemProvider: item.itemProvider)
		}
	}

}
