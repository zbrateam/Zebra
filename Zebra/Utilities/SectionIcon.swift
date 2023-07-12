//
//  SectionIcon.swift
//  Zebra
//
//  Created by Adam Demasi on 1/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

fileprivate struct SectionIconGradient {
	static let blue   = Self(assetName: "blue")
	static let gray   = Self(assetName: "gray")
	static let green  = Self(assetName: "green")
	static let orange = Self(assetName: "orange")
	static let purple = Self(assetName: "purple")
	static let red    = Self(assetName: "red")
	static let teal   = Self(assetName: "teal")
	static let yellow = Self(assetName: "yellow")

	let colors: [UIColor]

	init(assetName: String) {
		colors = [UIColor(named: "Sections/\(assetName).0")!, UIColor(named: "Sections/\(assetName).1")!]
	}
}

fileprivate extension UIImage {
	static func systemNamedImage(_ systemNames: String...) -> UIImage? {
		for name in systemNames {
			if let image = UIImage(systemName: name) {
				return image
			}
		}
		return nil
	}
}

struct SectionIcon {

	private static let sections: [String: SectionIcon] = [
		"Addons":             SectionIcon(image: .systemNamedImage("plus.app.fill"), gradient: .teal),
		"Administration":     SectionIcon(image: .systemNamedImage("gearshape.fill"), gradient: .gray),
		"Applications":       SectionIcon(image: .systemNamedImage("star.square.fill"), gradient: .blue),
		"Archiving":          SectionIcon(image: .systemNamedImage("doc.zipper"), gradient: .orange),
		"Books":              SectionIcon(image: .systemNamedImage("books.vertical.fill"), gradient: .orange),
		"Carrier Bundles":    SectionIcon(image: .systemNamedImage("antenna.radiowaves.left.and.right"), gradient: .green),
		"Data Storage":       SectionIcon(image: .systemNamedImage("externaldrive.fill"), gradient: .gray),
		"Development":        SectionIcon(image: .systemNamedImage("hammer.fill"), gradient: .orange),
		"devel":              SectionIcon(image: .systemNamedImage("hammer.fill"), gradient: .orange),
		"Dictionaries":       SectionIcon(image: .systemNamedImage("character.book.closed.fill"), gradient: .teal),
		"Education":          SectionIcon(image: .systemNamedImage("graduationcap.fill"), gradient: .green),
		"Entertainment":      SectionIcon(image: .systemNamedImage("film"), gradient: .blue),
		"Fonts":              SectionIcon(image: .systemNamedImage("textformat.alt"), gradient: .red),
		"Games":              SectionIcon(image: .systemNamedImage("gamecontroller.fill"), gradient: .green),
		"Health and Fitness": SectionIcon(image: .systemNamedImage("heart.fill"), gradient: .red),
		"Java":               SectionIcon(image: .systemNamedImage("cup.and.saucer.fill"), gradient: .blue),
		"Keyboards":          SectionIcon(image: .systemNamedImage("keyboard.fill", "keyboard"), gradient: .teal),
		"Keyrings":           SectionIcon(image: .systemNamedImage("key.fill"), gradient: .red),
		"Libraries":          SectionIcon(image: .systemNamedImage("slider.horizontal.3"), gradient: .red),
		"libs":               SectionIcon(image: .systemNamedImage("slider.horizontal.3"), gradient: .red),
		"Localizations":      SectionIcon(image: .systemNamedImage("flag.fill"), gradient: .green),
		"Messaging":          SectionIcon(image: .systemNamedImage("ellipsis.bubble.fill"), gradient: .red),
		"Multimedia":         SectionIcon(image: .systemNamedImage("camera.on.rectangle.fill"), gradient: .blue),
		"Navigation":         SectionIcon(image: .systemNamedImage("arrow.triangle.turn.up.right.diamond.fill"), gradient: .orange),
		"Networking":         SectionIcon(image: .systemNamedImage("network"), gradient: .green),
		"Packaging":          SectionIcon(image: .systemNamedImage("shippingbox.fill"), gradient: .teal),
		"Perl":               SectionIcon(image: .systemNamedImage("chevron.left.slash.chevron.right"), gradient: .red),
		"perl":               SectionIcon(image: .systemNamedImage("chevron.left.slash.chevron.right"), gradient: .red),
		"Repositories":       SectionIcon(image: .systemNamedImage("list.bullet"), gradient: .red),
		"Ringtones":          SectionIcon(image: .systemNamedImage("candybarphone"), gradient: .teal),
		"Scripting":          SectionIcon(image: .systemNamedImage("chevron.left.slash.chevron.right"), gradient: .red),
		"Security":           SectionIcon(image: .systemNamedImage("lock.\(UIDevice.current.deviceSymbolName)", "lock"), gradient: .teal),
		"shells":             SectionIcon(image: .systemNamedImage("terminal"), gradient: .orange),
		"Site-Specific Apps": SectionIcon(image: .systemNamedImage("doc.append.fill"), gradient: .red),
		"Social":             SectionIcon(image: .systemNamedImage("person.3.fill"), gradient: .teal),
		"Soundboards":        SectionIcon(image: .systemNamedImage("speaker.wave.3.fill"), gradient: .purple),
		"Stickers":           SectionIcon(image: .systemNamedImage("face.smiling"), gradient: .purple),
		"System":             SectionIcon(image: .systemNamedImage(UIDevice.current.specificDeviceSymbolName, "iphone"), gradient: .red),
		"Terminal Support":   SectionIcon(image: .systemNamedImage("terminal"), gradient: .orange),
		"text":               SectionIcon(image: .systemNamedImage("square.and.pencil"), gradient: .red),
		"Text Editors":       SectionIcon(image: .systemNamedImage("square.and.pencil"), gradient: .red),
		"Themes":             SectionIcon(image: .systemNamedImage("paintbrush.fill"), gradient: .blue),
		"Toys":               SectionIcon(image: .systemNamedImage("wand.and.stars"), gradient: .purple),
		"Tweaks":             SectionIcon(image: .systemNamedImage("wrench.and.screwdriver.fill"), gradient: .yellow),
		"Utilities":          SectionIcon(image: .systemNamedImage("suitcase.fill"), gradient: .teal),
		"Wallpaper":          SectionIcon(image: .systemNamedImage("photo"), gradient: .purple),
		"Widgets":            SectionIcon(image: .systemNamedImage("plus.app.fill"), gradient: .purple),
		"XML":                SectionIcon(image: .systemNamedImage("chevron.left.slash.chevron.right"), gradient: .red),
		"X11":                SectionIcon(image: .systemNamedImage("macwindow.on.rectangle"), gradient: .blue),
		"X Window":           SectionIcon(image: .systemNamedImage("macwindow.on.rectangle"), gradient: .blue)
	]

	private static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 45, weight: .medium, scale: .large)
		.withHierarchicalColor(.white)

	private static var cachedIcons = [String: UIImage]()

	static func icon(for section: String?) -> UIImage? {
		guard let section = section?.baseSectionName,
					let sectionIcon = Self.sections[section] else {
			return nil
		}

		if let icon = cachedIcons[section] {
			return icon
		}

		let iconRect = CGRect(x: 0, y: 0, width: 60, height: 60)
		let icon = UIGraphicsImageRenderer(bounds: iconRect).image { context in
			// Colors space, iPods shuffle https://www.engadget.com/2005-01-19-engadget-investigates-is-it-ipod-shuffles-or-ipods.html
			let colors = sectionIcon.gradient.colors.map(\.cgColor)
			if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
																	 colors: colors as CFArray,
																	 locations: nil) {
				context.cgContext.drawLinearGradient(gradient,
																						 start: .zero,
																						 end: CGPoint(x: 0, y: iconRect.size.height),
																						 options: [])
			}

			if let image = sectionIcon.image {
				var finalImage = image.withConfiguration(Self.symbolConfiguration)
				if #unavailable(iOS 15) {
					finalImage = finalImage.withTintColor(.white)
				}

				// Scale glyph to fit
				var glyphSize = CGSize(width: 45, height: 45)
				if image.size.width > image.size.height {
					glyphSize.height /= image.size.width / image.size.height
				} else if image.size.height > image.size.width {
					glyphSize.width /= image.size.height / image.size.width
				}
				var glyphRect = iconRect.insetBy(dx: (iconRect.size.width - glyphSize.width) / 2,
																				 dy: (iconRect.size.height - glyphSize.height) / 2)
				let baselineOffset = (finalImage.baselineOffsetFromBottom ?? 0) / finalImage.scale
				glyphRect.origin.y -= (baselineOffset * (image.size.height / glyphSize.height)) / 4
				finalImage.draw(in: glyphRect)
			}
		}
		cachedIcons[section] = icon
		return icon
	}

	private let image: UIImage?
	private let gradient: SectionIconGradient

}
