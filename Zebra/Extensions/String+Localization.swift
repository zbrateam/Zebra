//
//  String+Localization.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 3/4/21.
//

import Foundation

#if os(iOS)
import UIKit
#endif

public extension String {
	static func localize(_ key: String, bundle: Bundle? = nil, tableName: String? = nil, comment: String = "") -> String {
		NSLocalizedString(key, tableName: tableName, bundle: bundle ?? .main, comment: comment)
	}

	static var openInBrowser: String {
		let app = Workspace.appNameForOpening(url: URL(string: "https://")!) ?? "Safari"
		return String(format: .localize("Open in %@"), app)
	}

#if os(iOS)
	private static let uikitBundle = Bundle(for: UIView.self)

	static var ok: String         { .localize("OK",       bundle: uikitBundle) }
	static var done: String       { .localize("Done",     bundle: uikitBundle) }
	static var cancel: String     { .localize("Cancel",   bundle: uikitBundle) }
	static var close: String      { .localize("Close",    bundle: uikitBundle) }
	static var back: String       { .localize("Back",     bundle: uikitBundle) }
	static var forward: String    { .localize("Forward",  bundle: uikitBundle) }
	static var `continue`: String { .localize("Continue", bundle: uikitBundle) }
	static var add: String        { .localize("Add",      bundle: uikitBundle) }
	static var copy: String       { .localize("Copy",     bundle: uikitBundle) }
	static var delete: String     { .localize("Delete",   bundle: uikitBundle) }
	static var share: String      { .localize("Share",    bundle: uikitBundle) }
#endif
}
