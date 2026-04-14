//
//  AttributedTextCell.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/4/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
  import UIKit
  import os.log

  private let logger = Logger(
    subsystem: "com.cocoanetics.DTCoreText", category: "AttributedTextCell")

  /// A table view cell that displays rich text via a `AttributedTextContentView`.
  @objc(DTAttributedTextCell)
  public class AttributedTextCell: UITableViewCell {

    private var _attributedTextContextView: AttributedTextContentView?

    private weak var _textDelegate: DTAttributedTextContentViewDelegate?

    private var htmlHash: Int = 0

    /// Whether the cell uses a fixed row height.
    @objc public var hasFixedRowHeight: Bool = false {
      didSet {
        if hasFixedRowHeight != oldValue {
          setNeedsLayout()
        }
      }
    }

    private weak var containingTableView: UITableView?

    // MARK: - Init

    /// Creates a cell with the default style and the given reuse identifier.
    @objc
    public init(reuseIdentifier: String?) {
      super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
      super.layoutSubviews()

      guard superview != nil else { return }

      // Honour the cell's layout margins so the text sits inside the standard
      // horizontal padding — the DT content view is a plain UIView and
      // doesn't pick those up on its own.
      let margins = contentView.layoutMargins
      let insetBounds = contentView.bounds.inset(
        by: UIEdgeInsets(
          top: 0, left: margins.left, bottom: 0, right: margins.right
        ))

      if hasFixedRowHeight {
        attributedTextContextView.frame = insetBounds
      } else {
        let neededHeight = requiredRowHeight(in: containingTableView)
        let frame = CGRect(
          x: insetBounds.origin.x, y: insetBounds.origin.y,
          width: insetBounds.size.width, height: neededHeight)
        attributedTextContextView.frame = frame
      }
    }

    // MARK: - Superview Detection

    private func findContainingTableView() -> UITableView? {
      var view = superview
      while let current = view {
        if let tableView = current as? UITableView {
          return tableView
        }
        view = current.superview
      }
      return nil
    }

    public override func didMoveToSuperview() {
      super.didMoveToSuperview()
      containingTableView = findContainingTableView()
    }

    // MARK: - Row Height

    /// Calculates the grouped-style table view cell margin for a given table width.
    private func groupedCellMargin(tableWidth: CGFloat) -> CGFloat {
      guard tableWidth > 20 else {
        return tableWidth - 10
      }

      if tableWidth < 400 || UIDevice.current.userInterfaceIdiom == .phone {
        return 10
      } else {
        return max(31, min(45, tableWidth * 0.06))
      }
    }

    /// Returns the required row height for this cell in the given table view.
    @objc(requiredRowHeightInTableView:)
    public func requiredRowHeight(in tableView: UITableView?) -> CGFloat {
      if hasFixedRowHeight {
        logger.warning("requiredRowHeight(in:) called on a cell configured with fixed row height")
      }

      guard let tableView else { return 0 }

      var contentWidth = tableView.frame.width

      // Reduce width for accessories (iOS 16+ layout only)
      switch accessoryType {
      case .disclosureIndicator:
        contentWidth -= 10.0 + 8.0 + 15.0
      case .checkmark:
        contentWidth -= 10.0 + 14.0 + 15.0
      case .detailDisclosureButton:
        contentWidth -= 10.0 + 42.0 + 15.0
      case .detailButton:
        contentWidth -= 10.0 + 22.0 + 15.0
      case .none:
        break
      @unknown default:
        logger.warning(
          "AccessoryType \(self.accessoryType.rawValue) not implemented on \(type(of: self))")
      }

      // Match the horizontal layout-margin inset applied in layoutSubviews()
      // so the height calculation uses the same available width.
      let margins = contentView.layoutMargins
      contentWidth -= margins.left + margins.right

      let neededSize = attributedTextContextView.suggestedFrameSizeToFitEntireStringConstrainted(
        toWidth: contentWidth)
      return neededSize.height
    }

    // MARK: - HTML Content

    /// Sets the cell content from an HTML string.
    @objc
    public func setHTMLString(_ html: String) {
      setHTMLString(html, options: nil)
    }

    /// Sets the cell content from an HTML string with options.
    @objc
    public func setHTMLString(_ html: String, options: [String: Any]?) {
      let newHash = html.hashValue

      guard newHash != htmlHash else { return }
      htmlHash = newHash

      guard let data = html.data(using: .utf8) else { return }
      let string = NSAttributedString(
        htmlData: data, options: options ?? [:], documentAttributes: nil)
      self.attributedString = string

      setNeedsLayout()
    }

    // MARK: - Properties

    /// The attributed string displayed by this cell.
    @objc public var attributedString: NSAttributedString? {
      get { return _attributedTextContextView?.attributedString }
      set { attributedTextContextView.attributedString = newValue }
    }

    /// The delegate that provides custom subviews for images and links.
    @objc public weak var textDelegate: DTAttributedTextContentViewDelegate? {
      get { return _textDelegate }
      set {
        _textDelegate = newValue
        _attributedTextContextView?.delegate = newValue
      }
    }

    /// The attributed text content view used to display rich text.
    @objc public var attributedTextContextView: AttributedTextContentView {
      if let existing = _attributedTextContextView {
        return existing
      }

      let view = AttributedTextContentView(frame: contentView.bounds)
      view.edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
      view.layoutFrameHeightIsConstrainedByBounds = hasFixedRowHeight
      view.delegate = _textDelegate
      contentView.addSubview(view)
      _attributedTextContextView = view
      return view
    }
  }

#endif
