//
//  SourceCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class SourceCollectionViewCell: UICollectionViewCell {

	var source: Source! {
		didSet { updateSource() }
	}

	private var imageView: IconImageView!
	private var symbolImageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailImageView: UIImageView!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!
	private var progressView: ProgressDonut!

	private var niceSourceURL: String?

	override init(frame: CGRect) {
		super.init(frame: frame)

		let imageContainer = UIView()
		imageContainer.translatesAutoresizingMaskIntoConstraints = false

		imageView = IconImageView()
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageContainer.addSubview(imageView)

		symbolImageView = UIImageView()
		symbolImageView.translatesAutoresizingMaskIntoConstraints = false
		symbolImageView.contentMode = .scaleAspectFit
		symbolImageView.tintColor = .secondaryLabel
		imageContainer.addSubview(symbolImageView)

		titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.textColor = .label

		detailLabel = UILabel()
		detailLabel.font = .preferredFont(forTextStyle: .footnote)
		detailLabel.textColor = .secondaryLabel

		detailImageView = UIImageView()
		detailImageView.translatesAutoresizingMaskIntoConstraints = false
		detailImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: detailLabel.font, scale: .small)
		detailImageView.tintColor = .secondaryLabel

		let detailStackView = UIStackView(arrangedSubviews: [detailImageView, detailLabel])
		detailStackView.spacing = 4
		detailStackView.alignment = .center

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailStackView])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		progressView = ProgressDonut()
		progressView.isHidden = true

		chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
		chevronImageView.tintColor = .tertiaryLabel

		let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
		chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium, scale: .medium)

		let mainStackView = UIStackView(arrangedSubviews: [imageContainer, labelStackView, progressView, chevronImageView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 12
		contentView.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
			mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

			imageView.widthAnchor.constraint(equalToConstant: 40),
			imageView.heightAnchor.constraint(equalToConstant: 40),

			symbolImageView.widthAnchor.constraint(equalToConstant: 30),
			symbolImageView.heightAnchor.constraint(equalToConstant: 30),
			symbolImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
			symbolImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		source = nil
		super.prepareForReuse()
	}

	override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)

		if newSuperview == nil {
			NotificationCenter.default.removeObserver(self, name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		} else {
			NotificationCenter.default.addObserver(self, selector: #selector(self.progressDidChange), name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		}
	}

	private func updateSource() {
		if let source = source {
			let url = source.uri
			var urlString = url.absoluteString
			if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
				urlString = urlString.replacingOccurrences(regex: "^https?://", with: "")
			}
			if urlString.last == "/" {
				urlString.removeLast()
			}
			niceSourceURL = urlString

			if let host = source.uri.host,
				 let image = UIImage(named: "Repo Icons/\(host)") {
				imageView.imageURL = nil
				imageView.image = image
			} else {
				imageView.imageURL = source.iconURL
			}

			imageView.isHidden = false
			symbolImageView.isHidden = true
			titleLabel.text = source.origin
			titleLabel.textColor = .label

			let state = SourceRefreshController.shared.sourceStates[source.uuid]
			updateProgress(state: state)
		} else {
			titleLabel.text = .localize("All Packages")
			detailLabel.text = .localize("Browse packages from all sources.")
			imageView.imageURL = nil
			imageView.isHidden = true
			symbolImageView.image = UIImage(named: "zebra.wrench")
			symbolImageView.isHidden = false
			detailImageView.isHidden = true
			progressView.isHidden = true
		}
	}

	private func updateProgress(state: SourceRefreshController.SourceState?) {
		if source != nil {
			if SourceRefreshController.shared.isRefreshing,
				 let progress = state?.progress {
				progressView.isHidden = false
				progressView.progress = progress.fractionCompleted
			} else {
				progressView.isHidden = true
			}

			if let errors = state?.errors,
				 !errors.isEmpty {
				detailImageView.image = UIImage(systemName: "exclamationmark.circle")
				detailImageView.isHidden = false
				detailImageView.tintColor = .systemRed
				detailLabel.text = .localize("Failed to load")
				detailLabel.textColor = .systemRed
			} else {
				detailImageView.isHidden = true
				detailLabel.text = niceSourceURL
				detailLabel.textColor = .secondaryLabel
			}
		}
	}

	@objc private func progressDidChange() {
		guard let source = source else {
			return
		}
		let state = SourceRefreshController.shared.sourceStates[source.uuid]
		DispatchQueue.main.async {
			self.updateProgress(state: state)
		}
	}

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}

}
