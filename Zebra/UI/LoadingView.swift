//
//  LoadingView.swift
//  Zebra
//
//  Created by Adam Demasi on 17/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class LoadingView: UIView {

	private var activityIndicator: UIActivityIndicatorView!
	private var slowTimer: Timer?

	override init(frame: CGRect) {
		super.init(frame: frame)

		activityIndicator = UIActivityIndicatorView(style: .medium)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.color = .secondaryLabel
		addSubview(activityIndicator)

		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)
		updateState(superview: newSuperview)
	}

	override var isHidden: Bool {
		didSet { updateState(superview: superview) }
	}

	private func updateState(superview: UIView?) {
		activityIndicator.stopAnimating()

		if superview == nil || isHidden {
			slowTimer?.invalidate()
			slowTimer = nil
		} else {
			slowTimer = Timer.scheduledTimer(timeInterval: 0.5,
																			 target: activityIndicator!,
																			 selector: #selector(UIActivityIndicatorView.startAnimating),
																			 userInfo: nil,
																			 repeats: false)
		}
	}

}
