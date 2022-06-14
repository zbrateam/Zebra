//
//  NavigationBar.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {

	let progressBar = ProgressBar(progressViewStyle: .bar)

	override init(frame: CGRect) {
		super.init(frame: frame)

		progressBar.translatesAutoresizingMaskIntoConstraints = false
		addSubview(progressBar)

		NSLayoutConstraint.activate([
			progressBar.topAnchor.constraint(equalTo: self.bottomAnchor),
			progressBar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			progressBar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			progressBar.heightAnchor.constraint(equalToConstant: 1)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension UIViewController {
	var navigationProgressBar: ProgressBar? { (navigationController?.navigationBar as? NavigationBar)?.progressBar }
}
