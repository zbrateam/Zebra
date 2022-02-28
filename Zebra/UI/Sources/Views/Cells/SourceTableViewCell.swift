//
//  SourceTableViewCell.swift
//  Zebra
//
//  Created by Amy While on 27/12/2021.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

import UIKit
import Evander

@objc(ZBSourceTableViewCell)
class SourceTableViewCell: UITableViewCell {
    
    private var iconLink: URL?
    
    @objc public var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 34),
            imageView.widthAnchor.constraint(equalToConstant: 34)
        ])
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = 34 * 0.2237
        imageView.layer.cornerCurve = .continuous
        imageView.layer.borderColor = UIColor.imageBorder.cgColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    @objc public var sourceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.highlightedTextColor = .black
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    @objc public  var urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.highlightedTextColor = .black
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var installedPackagesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.highlightedTextColor = .black
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var nameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 35).isActive = true
        stackView.addArrangedSubview(sourceLabel)
        stackView.addArrangedSubview(urlLabel)
        return stackView
    }()
    
    private var storeBadge: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Store")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var storeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(storeBadge)
        return stackView
    }()
    
    private var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .gray
        return spinner
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameStackView)
        contentView.addSubview(storeStackView)
        contentView.addSubview(installedPackagesLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            nameStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            nameStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            installedPackagesLabel.bottomAnchor.constraint(equalTo: urlLabel.bottomAnchor),
            installedPackagesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            storeStackView.leadingAnchor.constraint(equalTo: nameStackView.trailingAnchor, constant: 8),
            storeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            storeStackView.topAnchor.constraint(equalTo: sourceLabel.topAnchor)
        ])
        
        tintColor = .accent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        iconLink = nil
    }
        
    @objc public func setSource(_ source: PLSource) {
        sourceLabel.text = source.origin
        urlLabel.text  = source.uri.absoluteString
        
        iconLink = source.iconURL
        EvanderNetworking.image(url: iconLink, condition: { [weak self] in self?.iconLink == source.iconURL }, imageView: iconImageView, fallback: UIImage(named: "Unknown"))
    }
    
    @objc public var spinning: Bool = false {
        didSet {
            Thread.mainBlock { [self] in
                if spinning {
                    accessoryView = spinner
                    spinner.startAnimating()
                } else {
                    spinner.stopAnimating()
                    accessoryView = nil
                }
            }
        }
    }
    
    @objc public var disabled: Bool = false {
        didSet {
            Thread.mainBlock { [self] in
                if disabled {
                    selectionStyle = .none
                    alpha = 0.5
                } else {
                    selectionStyle = .default
                    alpha = 1
                }
            }
        }
    }
}

/*
 - (void)setSource:(PLSource *)source {
     self.sourceLabel.text = source.origin;
     self.urlLabel.text = source.URI.absoluteString;
 //    self.storeBadge.hidden = source.paymentEndpointURL == NULL;

 //    if ([ZBSettings wantsInstalledPackagesCount] || filter.sortOrder == ZBSourceSortOrderInstalledPackages) {
 //        NSUInteger numberOfInstalledPackages = [source numberOfInstalledPackages];
 //        if (numberOfInstalledPackages > 0) {
 //            self.installedPackagesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Installed", @""), numberOfInstalledPackages];
 //            self.installedPackagesLabel.hidden = NO;
 //        } else {
 //            self.installedPackagesLabel.hidden = YES;
 //        }
 //    } else {
 //        self.installedPackagesLabel.hidden = YES;
 //    }

     [self.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];

 //    if (source.errors.count) {
 //        self.accessoryType = [source isKindOfClass:[ZBSource class]] ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDetailButton;
 //        self.tintColor = [UIColor systemPinkColor];
 //    } else if (source.warnings.count) {
 //        self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
 //        self.tintColor = [UIColor systemYellowColor];
 //    }
 }
 */
