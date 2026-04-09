# Plan: Issue #1305 — Replace DTHTMLParser with SwiftText HTMLParser

## Problem

DTCoreText depends on `DTFoundation` solely for `DTHTMLParser` (an ObjC libxml2 SAX wrapper). Issue #1305 asks us to swap it out for SwiftText's `HTMLParser` (also libxml2-backed, but with a Swift delegate protocol). This blocks removing the DTFoundation dependency entirely.

The core challenge: `DTHTMLAttributedStringBuilder` implements `DTHTMLParserDelegate` (ObjC protocol). SwiftText's `HTMLParserDelegate` is a **pure Swift protocol** with Swift-typed parameters (`[String: String]` instead of `NSDictionary`). An ObjC class cannot conform to it. Therefore, **the builder must be migrated to Swift first**.

## Approach: Incremental Migration with ObjC Compatibility

Add SwiftText as a package dependency (using the `SwiftTextHTML` product). Migrate the builder to Swift so it can conform to `HTMLParserDelegate`. Annotate with `@objc` to preserve backward compatibility.

## Phase 1: Add SwiftText dependency

**`Package.swift` changes:**
- Add SwiftText package dependency (from GitHub, with `HTML` trait)
- Add `SwiftTextHTML` product dependency to the `DTCoreText` target (alongside DTFoundation temporarily)
- Keep DTFoundation for now — other files still use `DTLog`, `NSString+DTURLEncoding`, etc.

## Phase 2: Migrate DTHTMLAttributedStringBuilder to Swift

This is the critical step — the builder is ~1000 lines of ObjC with GCD concurrency and block-based tag handlers.

1. **Create `DTHTMLAttributedStringBuilder.swift`** in `Core/Source/`
   - `@objc public class DTHTMLAttributedStringBuilder: NSObject`
   - Conform to `HTMLParserDelegate` (from SwiftText's HTMLParser module)
   - Preserve the exact same public API: `init(html:options:documentAttributes:)`, `generatedAttributedString()`, `willFlushCallback`, `parseErrorCallback`, `shouldKeepDocumentNodeTree`, `abortParsing()`
   - Internally use `HTMLParser` (from SwiftText) instead of `DTHTMLParser`
   - The builder calls ObjC classes (DTHTMLElement, DTCSSStylesheet, etc.) — these bridge to Swift naturally

2. **Remove** `DTHTMLAttributedStringBuilder.h` and `.m`

3. **Update imports** — ObjC files that imported the builder header will get it via the generated `-Swift.h` header

4. **Validate** with the 50+ existing Swift tests in HTMLAttributedStringBuilderTests.swift

## Phase 3: Remove DTFoundation Dependency (future)

1. Audit remaining DTFoundation uses:
   - `DTLog.h` — replace with `os_log` or Swift `Logger`
   - `NSString+DTURLEncoding` — inline the few methods used
2. Remove `DTFoundation` from `Package.swift`
3. Remove `Externals/DTFoundation` submodule

## Key Design Decisions

- **ObjC compatibility**: Swift builder gets `@objc` so existing ObjC consumers still work. Callback blocks remain ObjC-compatible types.
- **Concurrency model**: Preserve the existing 3-queue GCD model. No async/await yet.
- **Tag handlers**: `_tagStartHandlers`/`_tagEndHandlers` become `[String: () -> Void]` dictionaries.
- **Delegate mapping** (1:1):

  | DTHTMLParserDelegate (ObjC) | HTMLParserDelegate (Swift) |
  |---|---|
  | `parser:didStartElement:attributes:` (NSDictionary) | `parser(_:didStartElement:attributes:)` ([String:String]) |
  | `parser:didEndElement:` | `parser(_:didEndElement:)` |
  | `parser:foundCharacters:` | `parser(_:foundCharacters:)` |
  | `parser:foundCDATA:` | `parser(_:foundCDATA:)` |
  | `parser:foundComment:` | `parser(_:foundComment:)` |
  | `parser:parseErrorOccurred:` (NSError) | `parser(_:parseErrorOccurred:)` (Error) |

## Files Changed

**Modified:**
- `Package.swift` — add SwiftText dependency, add SwiftTextHTML to DTCoreText target

**New:**
- `Core/Source/DTHTMLAttributedStringBuilder.swift`

**Removed:**
- `Core/Source/DTHTMLAttributedStringBuilder.h`
- `Core/Source/DTHTMLAttributedStringBuilder.m`

## Risks & Mitigations

- **Character accumulation**: SwiftText's parser accumulates characters before reporting (fewer `foundCharacters` calls). Should be an improvement but needs test validation.
- **GCD capture semantics**: ObjC `__weak`/`__strong` dance → Swift `[weak self]`. Careful translation needed.
- **Existing ObjC consumers**: `@objc` annotation + generated header ensures API compatibility.
