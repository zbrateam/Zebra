//
//  ProgressBar.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class ProgressBar: UIProgressView {
	override func setProgress(_ progress: Float, animated: Bool) {
		let reallyAnimated = animated && progress > self.progress
		if reallyAnimated {
			alpha = progress == 0 ? 0 : 1

			if progress >= 1 {
				UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
					super.setProgress(progress, animated: true)
				}
				UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseOut) {
					self.alpha = 0
				} completion: { _ in
					super.setProgress(0, animated: false)
				}
			} else {
				UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
					super.setProgress(progress, animated: true)
				}
			}
		} else {
			super.setProgress(progress, animated: false)
			alpha = progress > 0 && progress < 1 ? 1 : 0
		}
	}
}
