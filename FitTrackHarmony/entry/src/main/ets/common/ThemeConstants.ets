export class ThemeColors {
  id: string = ''
  name: string = ''
  desc: string = ''
  icon: string = ''
  bgPrimary: string = ''
  bgSecondary: string = ''
  bgCard: string = ''
  bgElevated: string = ''
  bgOverlay: string = ''
  accentPrimary: string = ''
  accentSecondary: string = ''
  accentGlow: string = ''
  textPrimary: string = ''
  textSecondary: string = ''
  textMuted: string = ''
  borderColor: string = ''
  success: string = ''
  successBg: string = ''
  warning: string = ''
  info: string = ''
  infoBg: string = ''
  purple: string = ''
  purpleBg: string = ''
  radiusSm: number = 0
  radiusMd: number = 0
  radiusLg: number = 0
  radiusXl: number = 0
  radiusBtn: number = 0
  radiusInput: number = 0
  radiusAvatar: number = 0
  radiusBadge: number = 0
  radiusProgress: number = 0
  cardSpacing: number = 0
  sectionGap: number = 0
  cardPadding: number = 0
  btnPadding: number = 0
  borderWidth: number = 0
  fontSizeScale: number = 1
  fontWeightDisplay: number = 600
  textTransform: string = 'none'
  letterSpacingDisplay: number = 0
  navHeight: number = 68
  logoFontSize: number = 16
  accentTextColor: string = '#ffffff'
}

function createTheme(
  id: string, name: string, desc: string, icon: string,
  bgPrimary: string, bgSecondary: string, bgCard: string, bgElevated: string,
  bgOverlay: string, accentPrimary: string, accentSecondary: string, accentGlow: string,
  textPrimary: string, textSecondary: string, textMuted: string, borderColor: string,
  success: string, successBg: string, warning: string, info: string, infoBg: string,
  purple: string, purpleBg: string,
  radiusSm: number, radiusMd: number, radiusLg: number, radiusXl: number,
  radiusBtn: number, radiusInput: number, radiusAvatar: number, radiusBadge: number,
  radiusProgress: number, cardSpacing: number, sectionGap: number, cardPadding: number,
  btnPadding: number, borderWidth: number, fontSizeScale: number, fontWeightDisplay: number,
  textTransform: string, letterSpacingDisplay: number, navHeight: number, logoFontSize: number,
  accentTextColor: string,
): ThemeColors {
  const t = new ThemeColors()
  t.id = id
  t.name = name
  t.desc = desc
  t.icon = icon
  t.bgPrimary = bgPrimary
  t.bgSecondary = bgSecondary
  t.bgCard = bgCard
  t.bgElevated = bgElevated
  t.bgOverlay = bgOverlay
  t.accentPrimary = accentPrimary
  t.accentSecondary = accentSecondary
  t.accentGlow = accentGlow
  t.textPrimary = textPrimary
  t.textSecondary = textSecondary
  t.textMuted = textMuted
  t.borderColor = borderColor
  t.success = success
  t.successBg = successBg
  t.warning = warning
  t.info = info
  t.infoBg = infoBg
  t.purple = purple
  t.purpleBg = purpleBg
  t.radiusSm = radiusSm
  t.radiusMd = radiusMd
  t.radiusLg = radiusLg
  t.radiusXl = radiusXl
  t.radiusBtn = radiusBtn
  t.radiusInput = radiusInput
  t.radiusAvatar = radiusAvatar
  t.radiusBadge = radiusBadge
  t.radiusProgress = radiusProgress
  t.cardSpacing = cardSpacing
  t.sectionGap = sectionGap
  t.cardPadding = cardPadding
  t.btnPadding = btnPadding
  t.borderWidth = borderWidth
  t.fontSizeScale = fontSizeScale
  t.fontWeightDisplay = fontWeightDisplay
  t.textTransform = textTransform
  t.letterSpacingDisplay = letterSpacingDisplay
  t.navHeight = navHeight
  t.logoFontSize = logoFontSize
  t.accentTextColor = accentTextColor
  return t
}

export const THEME_LIST: ThemeColors[] = [
  createTheme('iron-forge', '硬核铁馆', '男性健身玩家', '🏋️',
    '#0a0e14', '#0f1520', '#141c28', '#1a2436', '#0a0e14F8',
    '#ef4444', '#f97316', '#ef444440', '#f1f5f9', '#94a3b8', '#475569', '#ffffff14',
    '#22c55e', '#22c55e1F', '#f59e0b', '#3b82f6', '#3b82f61F', '#a855f7', '#a855f71F',
    0, 0, 0, 0, 0, 0, 4, 0, 0, 16, 20, 18, 16, 3, 1, 800,
    'uppercase', 2, 68, 16, '#000000'),
  createTheme('blossom', '柔美花语', '女性优雅健身', '🌸',
    '#fdf2f8', '#fce7f3', '#ffffff', '#fdf2f8', '#fdf2f8F8',
    '#ec4899', '#f472b6', '#ec48992E', '#1e1b2e', '#6b5f7b', '#a89bb8', '#ec48991A',
    '#10b981', '#10b98114', '#f59e0b', '#8b5cf6', '#8b5cf614', '#a855f7', '#a855f714',
    12, 18, 24, 32, 50, 14, 50, 50, 50, 20, 28, 22, 16, 1, 1, 600,
    'none', 0.5, 76, 22, '#ffffff'),
  createTheme('silver-care', '长者关怀', '大字清晰易读', '🛡️',
    '#ffffff', '#f0fdf4', '#ffffff', '#f0fdf4', '#ffffffFA',
    '#059669', '#10b981', '#05966926', '#111827', '#374151', '#6b7280', '#05966926',
    '#059669', '#0596691A', '#d97706', '#2563eb', '#2563eb1A', '#7c3aed', '#7c3aed1A',
    10, 14, 18, 22, 14, 12, 50, 8, 8, 20, 28, 24, 20, 2, 1.2, 700,
    'none', 0.5, 84, 24, '#ffffff'),
  createTheme('fresh-minimal', '清新极简', '简洁留白美学', '🍃',
    '#f8fafc', '#f1f5f9', '#ffffff', '#f8fafc', '#f8fafcF8',
    '#0ea5e9', '#38bdf8', '#0ea5e91F', '#0f172a', '#475569', '#94a3b8', '#0f172a0F',
    '#10b981', '#10b9810F', '#f59e0b', '#6366f1', '#6366f10F', '#8b5cf6', '#8b5cf60F',
    6, 10, 14, 18, 10, 8, 50, 6, 50, 24, 32, 20, 14, 1, 1, 600,
    'none', -0.5, 72, 18, '#ffffff'),
  createTheme('neon-cyber', '赛博霓虹', 'Z世代潮流玩家', '⚡',
    '#0a0015', '#0f0022', '#15002e', '#1f0044', '#0a0015FA',
    '#d946ef', '#e879f9', '#d946ef59', '#f5f3ff', '#a78bfa', '#6b5e9e', '#d946ef26',
    '#34d399', '#34d39926', '#fbbf24', '#22d3ee', '#22d3ee26', '#c084fc', '#c084fc26',
    2, 4, 6, 8, 4, 4, 4, 2, 2, 14, 18, 16, 14, 1, 1, 400,
    'uppercase', 3, 68, 18, '#0a0015'),
  createTheme('black-gold', '黑金尊享', '商务精英品质', '👑',
    '#0c0a09', '#12100e', '#1a1612', '#241e18', '#0c0a09FA',
    '#f59e0b', '#fbbf24', '#f59e0b33', '#fef3c7', '#a89f84', '#6b5a4e', '#f59e0b1A',
    '#10b981', '#10b9811A', '#f59e0b', '#93c5fd', '#93c5fd1A', '#c084fc', '#c084fc1A',
    6, 10, 14, 18, 10, 8, 50, 6, 4, 22, 28, 22, 16, 1, 1, 600,
    'uppercase', 3, 80, 22, '#0c0a09'),
]

export const DEFAULT_THEME_ID: string = 'iron-forge'

export function getThemeById(id: string): ThemeColors {
  for (const t of THEME_LIST) {
    if (t.id === id) {
      return t
    }
  }
  return THEME_LIST[0]
}

export function getCurrentTheme(): ThemeColors {
  const themeId: string = AppStorage.get('themeId') as string
  if (themeId !== undefined && themeId !== null && themeId !== '') {
    return getThemeById(themeId)
  }
  return getThemeById(DEFAULT_THEME_ID)
}

export function switchTheme(id: string): void {
  AppStorage.setOrCreate('themeId', id)
}
