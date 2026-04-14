//
//  HTMLAttributedStringBuilder.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
//  Migrated to Swift with async/await, April 2026.
//

import CoreGraphics
import Foundation
import HTMLParser
import os.log

#if canImport(CoreText)
  import CoreText
#endif

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

private let logger = Logger(
  subsystem: "com.cocoanetics.DTCoreText", category: "HTMLAttributedStringBuilder")


// MARK: - Builder

/// Builds an `NSAttributedString` from an HTML document.
public final class HTMLAttributedStringBuilder: @unchecked Sendable {

  private final class SyncResultBox: @unchecked Sendable {
    var result: NSAttributedString?
  }

  private let data: Data
  private let options: [String: Any]
  private let parser: HTMLParser
  private let state = BuilderState()

  // Cached result
  private var cachedResult: NSAttributedString?

  // MARK: - Public Properties

  /// Whether to preserve the document node tree after generation.
  public var shouldKeepDocumentNodeTree = false

  // MARK: - Init

  /// Creates a builder from HTML data.
  public init?(html data: Data, options: [String: Any]?) {
    self.data = data
    self.options = options ?? [:]

    var encoding: String.Encoding = .utf8
    if let encodingName = self.options[NSTextEncodingNameDocumentOption] as? String {
      let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
      if cfEncoding != kCFStringEncodingInvalidId {
        encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
      }
    }

    self.parser = HTMLParser(data: data, encoding: encoding)
  }

  // MARK: - Async API (preferred)

  /// Generates the attributed string asynchronously.
  public func generatedAttributedString() async -> NSAttributedString? {
    if let cachedResult { return cachedResult }
    guard !data.isEmpty else { return nil }

    await state.configure(
      options: options,
      shouldKeepDocumentNodeTree: shouldKeepDocumentNodeTree
    )

    for await event in parser.parseEvents() {
      if Task.isCancelled { break }
      await state.handle(event)
    }

    if Task.isCancelled { return nil }

    let result = await state.result()
    cachedResult = result
    return result
  }

  // MARK: - Sync API

  /// Generates and returns the attributed string from the HTML.
  /// Blocks the calling thread. Prefer the async version for Swift callers.
  public func generatedAttributedString() -> NSAttributedString? {
    if let cachedResult { return cachedResult }

    let semaphore = DispatchSemaphore(value: 0)
    let resultBox = SyncResultBox()

    // IMPORTANT: must be `Task.detached`, not `Task { ... }`. A non-detached
    // Task inherits the calling actor, which means if this is called from
    // the main thread the spawned Task, and the inner Task that
    // SwiftText's `HTMLParser.parseEvents()` spawns to drive libxml2, will
    // both try to run on the main actor. The main thread is blocked on the
    // semaphore below, so the parser can never run, and the wait deadlocks.
    Task.detached(priority: .userInitiated) { [self, semaphore, resultBox] in
      resultBox.result = await self.generatedAttributedString()
      semaphore.signal()
    }

    semaphore.wait()
    cachedResult = resultBox.result
    return resultBox.result
  }

  /// Aborts the current parsing operation.
  public func abortParsing() {
    parser.abortParsing()
  }
}
