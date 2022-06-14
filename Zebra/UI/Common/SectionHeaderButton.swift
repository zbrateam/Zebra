//
//  SectionHeaderButton.swift
//  Zebra
//
//  Created by Adam Demasi on 7/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SectionHeaderButton: UIButton {

	var normalBackgroundColor: UIColor? = .systemGray5 {
		didSet {
			backgroundColor = normalBackgroundColor
		}
	}

	var highlightBackgroundColor: UIColor? = .systemGray2

	convenience init(title: String, image: UIImage? = nil, target: Any? = nil, action: Selector? = nil) {
		self.init(frame: .zero)

		translatesAutoresizingMaskIntoConstraints = false
		backgroundColor = normalBackgroundColor
		clipsToBounds = true
		layer.cornerCurve = .continuous
		setTitleColor(tintColor, for: .normal)
		titleLabel!.font = .preferredFont(forTextStyle: .footnote, weight: .bold)
		adjustsImageWhenHighlighted = false
		accessibilityLabel = title

		if let action = action {
			addTarget(target, action: action, for: .touchUpInside)
		}

		addTarget(self, action: #selector(didTouchDown), for: [.touchDown, .touchDragEnter])
		addTarget(self, action: #selector(didTouchUp), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])

		if let image = image {
			setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: titleLabel!.font.pointSize,
																																	weight: .bold,
																																	scale: .medium),
																			forImageIn: .normal)
			setImage(image, for: .normal)
		} else {
			setTitle(title.localizedUppercase, for: .normal)
			setImage(nil, for: .normal)
			contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
		}

		NSLayoutConstraint.activate([
			self.widthAnchor.constraint(greaterThanOrEqualTo: self.heightAnchor),
			self.heightAnchor.constraint(equalToConstant: 30)
		])
	}

	private override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		layer.cornerRadius = frame.size.height / 2
	}

	@objc private func didTouchDown() {
		guard let highlightBackgroundColor = highlightBackgroundColor else {
			return
		}
		backgroundColor = highlightBackgroundColor
	}

	@objc private func didTouchUp() {
		guard let normalBackgroundColor = normalBackgroundColor else {
			return
		}
		backgroundColor = normalBackgroundColor
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()

		setTitleColor(tintColor, for: .normal)
	}

}
