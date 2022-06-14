//
//  Preferences.swift
//  Zebra
//
//  Created by Adam Demasi on 14/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class Preferences: NSObject {

	private static let defaults = UserDefaults.standard

	static func setUp() {
		defaults.register(defaults: [
			"AccentColor": AccentColor.cornflowerBlue.rawValue,
			"WantsFeaturedPackages": true,
			"AutoRefresh": true,
			"SourceTimeout": 60,
			"Role": PackageRole.user.rawValue,
			"SwipeActionStyle": PackageListSwipeActionStyle.text.rawValue,
			"PackageSortingType": PackageListSort.alpha.rawValue,
			"FinishAutomatically": false
		])
	}

	// MARK: - Theming

	static var accentColor: AccentColor {
		get { AccentColor(rawValue: defaults.integer(forKey: "AccentColor")) ?? .cornflowerBlue }
		set { defaults.set(newValue, forKey: "AccentColor") }
	}

	static var appIconName: String? {
		get { UIApplication.shared.alternateIconName }
	}

	// MARK: - Language Settings

	static var appLanguages: [String]? {
		get { defaults.object(forKey: "AppleLanguages") as? [String] }
		set { defaults.set(newValue, forKey: "AppleLanguages") }
	}

	// MARK: - Filters

	static var filteredSections: [String] {
		get { defaults.object(forKey: "FilteredSections") as? [String] ?? [] }
		set { defaults.set(newValue, forKey: "FilteredSections") }
	}

	static var filteredSources: [String] {
		get { defaults.object(forKey: "FilteredSources") as? [String] ?? [] }
		set { defaults.set(newValue, forKey: "FilteredSources") }
	}

	static var filteredAuthors: [String] {
		get { defaults.object(forKey: "BlockedAuthors") as? [String] ?? [] }
		set { defaults.set(newValue, forKey: "BlockedAuthors") }
	}

	// MARK: - Featured

	static var showFeaturedCarousels: Bool {
		get { defaults.bool(forKey: "WantsFeaturedPackages") }
		set { defaults.set(newValue, forKey: "WantsFeaturedPackages") }
	}

	static var featuredFilteredSources: [String] {
		get { defaults.object(forKey: "FeaturedSourceBlacklist") as? [String] ?? [] }
		set { defaults.set(newValue, forKey: "FeaturedSourceBlacklist") }
	}

	static var showNewsCarousel: Bool {
		get { defaults.bool(forKey: "CommunityNews") }
		set { defaults.set(newValue, forKey: "CommunityNews") }
	}

	// MARK: - Refresh

	static var refreshSourcesAutomatically: Bool {
		get { defaults.bool(forKey: "AutoRefresh") }
		set { defaults.set(newValue, forKey: "AutoRefresh") }
	}

	static var sourceRefreshTimeout: TimeInterval {
		get { defaults.double(forKey: "SourceTimeout") }
		set { defaults.set(newValue, forKey: "SourceTimeout") }
	}

	// MARK: - Packages

	static var promptForPackageVersion: Bool {
		get { !defaults.bool(forKey: "AlwaysInstallLatest") }
		set { defaults.set(!newValue, forKey: "AlwaysInstallLatest") }
	}

	static var roleFilter: PackageRole {
		get { PackageRole(rawValue: defaults.integer(forKey: "Role")) ?? .user }
		set { defaults.set(newValue.rawValue, forKey: "Role") }
	}

	static var packageListSwipeActionStyle: PackageListSwipeActionStyle {
		get { PackageListSwipeActionStyle(rawValue: defaults.integer(forKey: "Role")) ?? .text }
		set { defaults.set(newValue.rawValue, forKey: "Role") }
	}

	static var packageListSort: PackageListSort {
		get { PackageListSort(rawValue: defaults.integer(forKey: "PackageSortingType")) ?? .alpha }
		set { defaults.set(newValue.rawValue, forKey: "PackageSortingType") }
	}

	// MARK: - Console

	static var exitConsoleAutomatically: Bool {
		get { defaults.bool(forKey: "FinishAutomatically") }
		set { defaults.set(newValue, forKey: "FinishAutomatically") }
	}

	// MARK: - Favorites

	static var favoritePackages: [String] {
		get { defaults.object(forKey: "Wishlist") as? [String] ?? [] }
		set { defaults.set(newValue, forKey: "Wishlist") }
	}

	// MARK: - Source Update

	static var lastSourceUpdate: Date {
		get { defaults.object(forKey: "lastUpdatedDate") as? Date ?? .distantPast }
		set { defaults.set(newValue, forKey: "lastUpdatedDate") }
	}

}
