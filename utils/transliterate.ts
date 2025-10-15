import { transliterate } from 'transliteration'

export function transliterateToLatin(text: string): string {
  return transliterate(text, { 
    replace: [
      [' ', '_'],
      ['-', '_'],
      ['.', ''],
      [',', ''],
      ['!', ''],
      ['?', ''],
      ['(', ''],
      [')', ''],
      ['[', ''],
      [']', ''],
      ['{', ''],
      ['}', ''],
      ['"', ''],
      ["'", ''],
      ['`', ''],
      ['~', ''],
      ['@', ''],
      ['#', ''],
      ['$', ''],
      ['%', ''],
      ['^', ''],
      ['&', ''],
      ['*', ''],
      ['+', ''],
      ['=', ''],
      ['|', ''],
      ['\\', ''],
      ['/', ''],
      ['<', ''],
      ['>', ''],
      [';', ''],
      [':', ''],
    ]
  }).toLowerCase()
}

export function generateUsername(name: string): string {
  const base = transliterateToLatin(name)
  const randomSuffix = Math.floor(1000 + Math.random() * 9000)
  return `${base}${randomSuffix}`
}

export function validateUsername(username: string): boolean {
  const usernameRegex = /^[a-z0-9_]{3,20}$/
  return usernameRegex.test(username)
}
