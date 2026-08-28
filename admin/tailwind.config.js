/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class', '[data-theme="dark"]'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  // Preflight désactivé : on ne veut pas réinitialiser le design CSS custom du dashboard.
  corePlugins: { preflight: false },
  theme: {
    extend: {
      colors: {
        border: 'var(--outline)',
        input: 'var(--outline)',
        ring: 'var(--primary)',
        background: 'var(--bg)',
        foreground: 'var(--text)',
        primary: {
          DEFAULT: 'var(--primary)',
          foreground: 'var(--primary-foreground, #ffffff)',
        },
        secondary: {
          DEFAULT: 'var(--surface)',
          foreground: 'var(--text)',
        },
        destructive: {
          DEFAULT: 'var(--danger)',
          foreground: 'var(--danger-foreground, #ffffff)',
        },
        muted: {
          DEFAULT: 'var(--surface)',
          foreground: 'var(--text-muted)',
        },
        accent: {
          DEFAULT: 'var(--hover)',
          foreground: 'var(--text)',
        },
        popover: {
          DEFAULT: 'var(--card)',
          foreground: 'var(--text)',
        },
        card: {
          DEFAULT: 'var(--card)',
          foreground: 'var(--text)',
        },
        sidebar: {
          DEFAULT: 'var(--card)',
          foreground: 'var(--text)',
          primary: 'var(--primary)',
          'primary-foreground': 'var(--primary-foreground, #ffffff)',
          accent: 'var(--hover)',
          'accent-foreground': 'var(--text)',
          border: 'var(--outline)',
          ring: 'var(--primary)',
        },
      },
      borderRadius: {
        lg: '16px',
        md: '12px',
        sm: '8px',
      },
    },
  },
  plugins: [],
};
