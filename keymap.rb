require 'i2c'
require 'mouse'

class MTCH6102
  ADDR = 0x25
  READ_ADDR = 0x25
  REG_STAT = 0x10
  REG_CMD = 0x04
  REG_MODE = 0x05
  REG_CFG_START = 0x20
  REG_CFG_END = 0x43
  TAP_HOLD_TIMEL = 0x3C

  class GESTURE
    CLICK = 0x10
    HOLD = 0x11
    DOBLE_CLICK = 0x20
    SWP_DWN = 0x31
    SWP_DWN_HLD = 0x32
    SWP_RGT = 0x41
    SWP_RGT_HLD=  0x42
    SWP_UP = 0x51
    SWP_UP_HLD = 0x52
    SWP_LFT = 0x61
    SWP_LFT_HLD = 0x62
  end

  attr_reader :button, :x, :y, :buf_x, :buf_y

  def initialize(i2c)
    @i2c = i2c
    @button = 0
    @buf_x = 0
    @buf_y = 0
  end

  def device_init
    config = [
      0x09, 0x06, 0x06, 0x37, 0x28, 0x85, 0x02, 0x4C, 0x06, 0x10, 0x04, 0x01, 0x01, 0x0A, 0x00, 0x14, 0x14, 0x02,
      0x01, 0x01, 0x05, 0x00, 0x00, 0x40, 0x40, 0x19, 0x19, 0x40, 0x32, 0x00, 0x0C, 0x20, 0x04, 0x2D, 0x2D, 0x25
    ]
    @i2c.write(ADDR, REG_MODE)
    @i2c.write(ADDR, REG_STAT)
    @i2c.write(ADDR, REG_CFG_START)
    @i2c.write(ADDR, config)
    @i2c.write(ADDR, REG_CMD)
    @i2c.write(ADDR, TAP_HOLD_TIMEL)
    @i2c.write(ADDR, 0x00, 0x00)
  end

  def reload()
    @i2c.write(ADDR, REG_STAT)
    read = @i2c.read(ADDR, 5).bytes
    self.process_mtch6102(*read)
  rescue => e
    puts e
    puts 'i2c error'
  end

  def process_mtch6102(state , x, y, lsb, gesture)
    read_data = {
      touchDetect: state[0],
      gestureDetect: state[1],
      x: (x<<4) | (lsb >> 4),
      y: (y << 4) | (lsb & 0xF),
      gesture: gesture
    }

    if (read_data[:touchDetect] == 1 && read_data[:gestureDetect] == 0) then
      # @x = read_data[:x] - @buf_x
      # @y = read_data[:y] - @buf_y
      @y = read_data[:x] - @buf_x
      @x = read_data[:y] - @buf_y
    else
      @x, @y = 0, 0
    end
    @buf_x = read_data[:x]
    @buf_y = read_data[:y]

    if (read_data[:gestureDetect] == 1)
      if (read_data[:gesture] == GESTURE::CLICK)
        @button = 1
      elsif (read_data[:gesture] == GESTURE::HOLD)
        @button = 2
      end
    else
      @button = 0
    end

    read_data
  end
end

kbd = Keyboard.new
kbd.split = true
kbd.init_pins(
  [ 8, 23, 9, 21 ],
  [ 4, 27, 5, 26, 6, 22 ]
)

kbd.add_layer :default, %i[
  KC_TAB    KC_Q    KC_W      KC_E     KC_R     KC_T          KC_Y     KC_U     KC_I      KC_O      KC_P KC_BSPACE
  CTL_ESC   KC_A    KC_S      KC_D     KC_F     KC_G          KC_H     KC_J     KC_K      KC_L KC_SCOLON  KC_QUOTE
  KC_LSFT   KC_Z    KC_X      KC_C     KC_V     KC_B          KC_N     KC_M KC_COMMA    KC_DOT  KC_SLASH   KC_RSFT
  KC_NO     KC_NO   CMD_LANG2 LOWER_NO KC_SPACE KC_SPACE  KC_ENTER KC_ENTER RAISE_NO ALT_LANG1   KC_NO     KC_NO
]
kbd.add_layer :raise, %i[
  KC_TAB  KC_EXLM KC_AT     KC_HASH     KC_DLR   KC_PERC     KC_CIRC  KC_AMPR    KC_ASTER     KC_LPRN KC_RPRN KC_BSPACE
  CTL_ESC KC_LABK KC_LCBR   KC_LBRACKET KC_LPRN  KC_QUOTE   KC_MINUS KC_EQUAL     KC_LCBR     KC_RCBR KC_PIPE    KC_GRAVE
  KC_LSFT KC_RABK KC_RCBR   KC_RBRACKET KC_RPRN  KC_DQUO     KC_UNDS  KC_PLUS KC_LBRACKET KC_RBRACKET KC_BSLS   KC_TILD
  KC_NO   KC_NO   CMD_LANG2 LOWER_NO    KC_SPACE KC_SPACE   KC_ENTER KC_ENTER    RAISE_NO   ALT_LANG1 KC_NO     KC_NO
]
kbd.add_layer :lower, %i[
  KC_TAB  KC_1    KC_2      KC_3        KC_4      KC_5           KC_6     KC_7     KC_8      KC_9     KC_0 KC_BSPACE
  CTL_ESC KC_F2   KC_F10    KC_F12      KC_LPRN   KC_QUOTE    KC_LEFT  KC_DOWN    KC_UP  KC_RIGHT KC_RIGHT   KC_NO
  KC_LSFT KC_RABK KC_RCBR   KC_RBRACKET KC_RPRN   KC_DQUO        KC_0     KC_1     KC_2      KC_3 KC_SLASH  KC_COMMA
   KC_NO CMD_LANG2 LOWER_NO    KC_SPACE  KC_SPACE   KC_ENTER KC_ENTER RAISE_NO ALT_LANG1  KC_NO     KC_NO
]

kbd.define_mode_key :CTL_ESC,     [ :KC_ESCAPE,            :KC_LCTL,                     120,              150 ]
kbd.define_mode_key :RAISE_NO,    [ :KC_NO,                :raise,                       120,              150 ]
kbd.define_mode_key :LOWER_NO,    [ :KC_NO,                :lower,                       120,              400 ]
kbd.define_mode_key :ALT_LANG1,   [ :KC_LANG1,             :KC_LALT,                     120,              400 ]
kbd.define_mode_key :CMD_LANG2,   [ :KC_LANG2,             :KC_RGUI,                     120,              400 ]

kbd.before_report do
 kbd.invert_sft if kbd.keys_include?(:KC_SCOLON)
end

# RGB LED
rgb = RGB.new(
  0,
  0,
  22,
  false
)

rgb.effect = :swirl
rgb.speed = 22
kbd.append rgb

# i2c
i2c = I2C.new({
  unit: :RP2040_I2C1,
  frequency: 100_000,
  sda_pin: 2,
  scl_pin: 3
})

# Init MTCH6102
mtch6102 = MTCH6102.new(i2c)
mtch6102.device_init

mouse = Mouse.new({driver: mtch6102})
mouse.task do |mouse, kbd|
  report = mouse.driver.reload
  if (report && (report[:touchDetect] == 1 || report[:gestureDetect] == 1))
    puts "#{report.values}"
    puts "#{[mouse.driver.button, mouse.driver.x, mouse.driver.y]}"
  end

  USB.merge_mouse_report(mouse.driver.button, mouse.driver.x, mouse.driver.y, 0, 0)
end
kbd.append mouse

kbd.start!
