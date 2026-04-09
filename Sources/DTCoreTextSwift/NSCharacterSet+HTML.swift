//
//  NSCharacterSet+HTML.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation

/// Category on NSCharacterSet to create character sets frequently used and relevant to HTML and CSS string manipulations.
extension NSCharacterSet {

    /// Creates an alpha-numeric character set, appropriate for tag names.
    @objc public static let dt_tagNameCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }()

    /// Creates an alpha-numeric character set with colon, dash, and underscore, appropriate for tag attribute names.
    @objc public static let dt_tagAttributeNameCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "-_:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }()

    /// Creates a character set of all whitespace and newline characters that can be ignored between HTML tags.
    @objc public static let dt_ignorableWhitespaceCharacterSet: CharacterSet = {
        var tmpSet = CharacterSet.whitespacesAndNewlines

        // remove all special unicode space characters
        let unicodeSpaces: [String] = [
            "\u{00a0}", // NON_BREAKING_SPACE
            "\u{1680}", // OGHAM_SPACE_MARK
            "\u{180e}", // MONGOLIAN_VOWEL_SEPARATOR
            "\u{2000}", // EN_QUAD
            "\u{2001}", // EM_QUAD
            "\u{2002}", // EN_SPACE
            "\u{2003}", // EM_SPACE
            "\u{2004}", // THREE_PER_EM_SPACE
            "\u{2005}", // FOUR_PER_EM_SPACE
            "\u{2006}", // SIX_PER_EM_SPACE
            "\u{2007}", // FIGURE_SPACE
            "\u{2008}", // PUNCTUATION_SPACE
            "\u{2009}", // THIN_SPACE
            "\u{200a}", // HAIR_SPACE
            "\u{200b}", // ZERO_WIDTH_SPACE
            "\u{202f}", // NARROW_NO_BREAK_SPACE
            "\u{205f}", // MEDIUM_MATHEMATICAL_SPACE
            "\u{3000}", // IDEOGRAPHIC_SPACE
            "\u{feff}", // ZERO_WIDTH_NO_BREAK_SPACE
        ]

        for space in unicodeSpaces {
            tmpSet.remove(charactersIn: space)
        }

        return tmpSet
    }()

    /// Creates a character set with the single quote and double quote characters.
    @objc public static let dt_quoteCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "'\"")
    }()

    /// Creates a character set with forward slash, closing angle bracket, and whitespace characters.
    @objc public static let dt_nonQuotedAttributeEndCharacterSet: CharacterSet = {
        var tmpSet = CharacterSet(charactersIn: "/>")
        tmpSet.formUnion(.whitespacesAndNewlines)
        return tmpSet
    }()

    /// Creates a character set for CSS attribute names (alphanumeric plus dash and underscore, no colon).
    @objc public static let dt_cssStyleAttributeNameCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    }()

    /// Character set of characters that make up values in CSS lengths.
    @objc public static let dt_cssLengthValueCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: ".0123456789")
    }()

    /// Character set of characters that make up units in CSS lengths.
    @objc public static let dt_cssLengthUnitCharacterSet: CharacterSet = {
        return CharacterSet(charactersIn: "pxtem")
    }()

    /// Character set of ASCII characters.
    @objc public static let dt_ASCIICharacterSet: CharacterSet = {
        var tmpSet = CharacterSet()
        tmpSet.insert(charactersIn: UnicodeScalar(32)...UnicodeScalar(127))
        return tmpSet
    }()
}
