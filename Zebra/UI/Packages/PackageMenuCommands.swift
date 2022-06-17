//
//  PackageMenuCommands.swift
//  Zebra
//
//  Created by Adam Demasi on 16/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

extension UIMenuElement {
	static func openInBrowser(url: URL?, webSchemesOnly: Bool = true, sender: UIViewController) -> UIAction? {
		guard let url = url else {
			return nil
		}
		return UIAction(title: .openInBrowser,
										image: UIImage(systemName: "safari")) { action in
			URLController.open(url: url, sender: sender, webSchemesOnly: webSchemesOnly)
		}
	}

	static func copy(text: String?) -> UIAction? {
		guard let text = text else {
			return nil
		}
		return UIAction(title: .copy,
										image: UIImage(systemName: "doc.on.doc")) { _ in
			UIPasteboard.general.string = text
		}
	}

	static func share(text: String?, url: URL?, sender: UIViewController, sourceView: UIView) -> UIAction? {
		guard text != nil || url != nil else {
			return nil
		}
		return UIAction(title: .share,
										image: UIImage(systemName: "square.and.arrow.up")) { action in
			let viewController = UIActivityViewController(activityItems: [text, url as Any].compact(),
																										applicationActivities: nil)
			viewController.popoverPresentationController?.sourceView = sourceView
			viewController.popoverPresentationController?.sourceRect = sourceView.bounds
			sender.present(viewController, animated: true, completion: nil)
		}
	}
}

struct PackageMenuCommands {

	static func contextMenuConfiguration(for package: Package, identifier: NSCopying, viewController: UIViewController, sourceView: UIView) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: identifier,
																			previewProvider: { PackageViewController(package: package) },
																			actionProvider: { _ in self.menu(for: package, viewController: viewController, sourceView: sourceView) })
	}

	static func menu(for package: Package, viewController: UIViewController, sourceView: UIView) -> UIMenu {
		let url = package.depictionURL ?? package.homepageURL
		let shareText = String(format: .localize("%@ by %@"),
													 package.name,
													 package.author?.name ?? package.maintainer?.name ?? .localize("Unknown"))
		return UIMenu(children: [
			.openInBrowser(url: url, sender: viewController),
			.share(text: shareText, url: url, sender: viewController, sourceView: sourceView)
		].compact())
	}

	static func packageViewController(identifier: String, sender: UIViewController) async -> PackageViewController? {
		let packages = await PackageManager.shared.fetchPackages(matchingFilter: { $0.identifier == identifier })
		guard let package = packages.first else {
			await MainActor.run {
				let alertController = UIAlertController(title: .localize("Couldn’t open package because it wasn’t found in your installed sources."),
																								message: .localize("You may need to refresh sources to see this package."),
																								preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: .ok, style: .cancel, handler: nil))
				sender.present(alertController, animated: true)
			}
			return nil
		}
		return await PackageViewController(package: package)
	}

}
