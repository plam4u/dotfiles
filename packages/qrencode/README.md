# README

## Usage

This creates a static PNG with your QR code.
`qrencode -o qrcode.png "https://your-url.com"`

Use -s 10 to set size, e.g.:
`qrencode -o qrcode.png -s 10 "https://your-url.com"`

Use -l H for highest error correction:
`qrencode -o qrcode.png -s 10 -l H "https://your-url.com"`
