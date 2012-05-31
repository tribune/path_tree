module PathTree
  module Patterns
    UPPER_A_PATTERN = /[\xC3\x80-\xC3\x85]/u.freeze
    LOWER_A_PATTERN = /[\xC3\xA0-\xC3\xA5]/u.freeze
    UPPER_E_PATTERN = /[\xC3\x88-\xC3\x8B]/u.freeze
    LOWER_E_PATTERN = /[\xC3\xA8-\xC3\xAB]/u.freeze
    UPPER_I_PATTERN = /[\xC3\x8C-\xC3\x8F]/u.freeze
    LOWER_I_PATTERN = /[\xC3\xAC-\xC3\xAF]/u.freeze
    UPPER_O_PATTERN = /[\xC3\x92-\xC3\x96\xC3\x98]/u.freeze
    LOWER_O_PATTERN = /[\xC3\xB2-\xC3\xB6\xC3\xB8]/u.freeze
    UPPER_U_PATTERN = /[\xC3\x99-\xC3\x9C]/u.freeze
    LOWER_U_PATTERN = /[\xC3\xB9-\xC3\xBC]/u.freeze
    UPPER_Y_PATTERN = /\xC3\x9D/u.freeze
    LOWER_Y_PATTERN = /[\xC3\xBD\xC3\xBF]/u.freeze
    UPPER_C_PATTERN = /\xC3\x87/u.freeze
    LOWER_C_PATTERN = /\xC3\xA7/u.freeze
    UPPER_N_PATTERN = /\xC3\x91/u.freeze
    LOWER_N_PATTERN = /\xC3\xB1/u.freeze
    UPPER_D_PATTERN = /\xC3\x90/u.freeze
    UPPER_AE_PATTERN = /\xC3\x86/u.freeze
    LOWER_AE_PATTERN = /\xC3\xA6/u.freeze
    SS_PATTERN = /\xC3\x9F/u.freeze
  end
end
