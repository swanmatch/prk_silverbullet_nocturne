require 'i2c'
require 'mouse'

# Initialize a Keyboard
kbd = Keyboard.new

# `split=` should happen before `init_pins`
kbd.split = true

# You can make right side the "anchor" (so-called "master")
# kbd.set_anchor(:right)

# Initialize GPIO assign
kbd.init_pins(
  [ 8, 23, 9, 21 ],
  [ 4, 27, 5, 26, 6, 22 ]
)

# default layer should be added at first
kbd.add_layer :default, %i[
  KC_TAB    KC_Q    KC_W      KC_E     KC_R     KC_T          KC_Y     KC_U     KC_I      KC_O      KC_P KC_BSPACE
  CTL_ESC   KC_A    KC_S      KC_D     KC_F     KC_G          KC_H     KC_J     KC_K      KC_L KC_SCOLON  KC_QUOTE
  KC_LSFT   KC_Z    KC_X      KC_C     KC_V     KC_B          KC_N     KC_M KC_COMMA    KC_DOT  KC_SLASH   KC_RSFT
  XXXXXXX   XXXXXXX CMD_LANG2 LOWER_NO KC_SPACE KC_SPACE  KC_ENTER KC_ENTER RAISE_NO ALT_LANG1   XXXXXXX   XXXXXXX
].map { |kc| kc == :XXXXXXX ? :KC_NO : kc }
kbd.add_layer :raise, %i[
  KC_TAB  KC_EXLM KC_AT     KC_HASH     KC_DLR   KC_PERC     KC_CIRC  KC_AMPR    KC_ASTER     KC_LPRN KC_RPRN KC_BSPACE
  CTL_ESC KC_LABK KC_LCBR   KC_LBRACKET KC_LPRN  KC_QUOTE   KC_MINUS KC_EQUAL     KC_LCBR     KC_RCBR KC_PIPE    KC_GRAVE
  KC_LSFT KC_RABK KC_RCBR   KC_RBRACKET KC_RPRN  KC_DQUO     KC_UNDS  KC_PLUS KC_LBRACKET KC_RBRACKET KC_BSLS   KC_TILD
  XXXXXXX XXXXXXX CMD_LANG2 LOWER_NO    KC_SPACE KC_SPACE   KC_ENTER KC_ENTER    RAISE_NO   ALT_LANG1 XXXXXXX   XXXXXXX
].map { |kc| kc == :XXXXXXX ? :KC_NO : kc }
kbd.add_layer :lower, %i[
  KC_TAB  KC_1    KC_2      KC_3        KC_4      KC_5           KC_6     KC_7     KC_8      KC_9     KC_0 KC_BSPACE
  CTL_ESC KC_F2   KC_F10    KC_F12      KC_LPRN   KC_QUOTE    KC_LEFT  KC_DOWN    KC_UP  KC_RIGHT KC_RIGHT   XXXXXXX
  KC_LSFT KC_RABK KC_RCBR   KC_RBRACKET KC_RPRN   KC_DQUO        KC_0     KC_1     KC_2      KC_3 KC_SLASH  KC_COMMA
  XXXXXXX XXXXXXX CMD_LANG2 LOWER_NO    KC_SPACE  KC_SPACE   KC_ENTER KC_ENTER RAISE_NO ALT_LANG1  XXXXXXX   XXXXXXX
].map { |kc| kc == :XXXXXXX ? :KC_NO : kc }
#
#                   Your custom     Keycode or             Keycode (only modifiers)      Release time      Re-push time
#                   key name        Array of Keycode       or Layer Symbol to be held    threshold(ms)     threshold(ms)
#                                   or Proc                or Proc which will run        to consider as    to consider as
#                                   when you click         while you keep press          `click the key`   `hold the key`
kbd.define_mode_key :CTL_ESC,     [ :KC_ESCAPE,            :KC_LCTL,                     120,              150 ]
kbd.define_mode_key :RAISE_NO,    [ :KC_NO,                :raise,                       120,              150 ]
kbd.define_mode_key :LOWER_NO,    [ :KC_NO,                :lower,                       120,              400 ]
kbd.define_mode_key :ALT_LANG1,   [ :KC_LANG1,             :KC_LALT,                     120,              400 ]
kbd.define_mode_key :CMD_LANG2,   [ :KC_LANG2,             :KC_RGUI,                     120,              400 ]

# `before_report` will work just right before reporting what keys are pushed to USB host.
# You can use it to hack data by adding an instance method to Keyboard class by yourself.
# ex) Use Keyboard#before_report filter if you want to input `":" w/o shift` and `";" w/ shift`
kbd.before_report do
 kbd.invert_sft if kbd.keys_include?(:KC_SCOLON)
 # You'll be also able to write `invert_ctl`, `invert_alt` and `invert_gui`
end

# Initialize RGBLED with pin, underglow_size, backlight_size and is_rgbw.
rgb = RGB.new(
  0,    # pin number
  0,    # size of underglow pixel
  22,   # size of backlight pixel
  false # 32bit data will be sent to a pixel if true while 24bit if false
)

rgb.effect = :swirl
rgb.speed = 22
kbd.append rgb

MTCH6102_ADDR = 0x25
MTCH6102_READ_ADDR = 0x25
MTCH6102_REG_STAT = 0x10
MTCH6102_REG_CMD = 0x04
MTCH6102_REG_MODE = 0x05
MTCH6102_REG_CFG_START = 0x20
MTCH6102_REG_CFG_END = 0x43
MTCH6102_REG_HOLD_TIME = 0x3C
config = [0x09, 0x06, 0x06, 0x37, 0x28, 0x85, 0x02, 0x4C, 0x06, 0x10, 0x04, 0x01, 0x01, 0x0A, 0x00, 0x14, 0x14, 0x02, 0x01, 0x01, 0x05, 0x00, 0x00, 0x40, 0x40, 0x19, 0x19, 0x40, 0x32, 0x00, 0x0C, 0x20, 0x04, 0x2D, 0x2D, 0x25]

i2c = I2C.new({
  unit: :RP2040_I2C1,
  frequency: 100_000,
  sda_pin: 2,
  scl_pin: 3
})

# Init MTCH6102
i2c.write(MTCH6102_ADDR, MTCH6102_REG_MODE)
i2c.write(MTCH6102_ADDR, MTCH6102_REG_STAT)
i2c.write(MTCH6102_ADDR, MTCH6102_REG_CFG_START)
i2c.write(MTCH6102_ADDR, config)
i2c.write(MTCH6102_ADDR, MTCH6102_REG_CMD)
i2c.write(MTCH6102_ADDR, 0x20)
i2c.write(MTCH6102_ADDR, MTCH6102_REG_HOLD_TIME)
i2c.write(MTCH6102_ADDR, 0x10)

buf = {
  x: 0,
  y: 0,
}

mouse = Mouse.new({driver: i2c})
mouse.task do |mouse, kbd|
  mouse.driver.write(MTCH6102_ADDR, MTCH6102_REG_STAT)
  read = mouse.driver.read(MTCH6102_ADDR, 6).bytes
  y = -(buf[:y] - read[1]) * 10
  x = -(buf[:x] - read[2]) * 10

  USB.merge_mouse_report(0, x, y, 0, 0)
  puts("mouse report: #{read}")
  buf[:y] = read[1]
  buf[:x] = read[2]
end
kbd.append mouse

kbd.start!