module PathTree
  module Patterns
    UPPER_A_PATTERN = /\xC3[\x80-\x85]/.freeze
    LOWER_A_PATTERN = /\xC3[\xA0-\xA5]/.freeze
    UPPER_E_PATTERN = /\xC3[\x88-\x8B]/.freeze
    LOWER_E_PATTERN = /\xC3[\xA8-\xAB]/.freeze
    UPPER_I_PATTERN = /\xC3[\x8C-\x8F]/.freeze
    LOWER_I_PATTERN = /\xC3[\xAC-\xAF]/.freeze
    UPPER_O_PATTERN = /\xC3[\x92-\x96\x98]/.freeze
    LOWER_O_PATTERN = /\xC3[\xB2-\xB6\xB8]/.freeze
    UPPER_U_PATTERN = /\xC3[\x99-\x9C]/.freeze
    LOWER_U_PATTERN = /\xC3[\xB9-\xBC]/.freeze
    UPPER_Y_PATTERN = /\xC3\x9D/.freeze
    LOWER_Y_PATTERN = /\xC3[\xBD\xBF]/.freeze
    UPPER_C_PATTERN = /\xC3\x87/.freeze
    LOWER_C_PATTERN = /\xC3\xA7/.freeze
    UPPER_N_PATTERN = /\xC3\x91/.freeze
    LOWER_N_PATTERN = /\xC3\xB1/.freeze
    UPPER_D_PATTERN = /\xC3\x90/.freeze
    UPPER_AE_PATTERN = /\xC3\x86/.freeze
    LOWER_AE_PATTERN = /\xC3\xA6/.freeze
    SS_PATTERN = /\xC3\x9F/.freeze
  end
end
