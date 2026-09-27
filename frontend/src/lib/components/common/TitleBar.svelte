<script lang="ts">
  import Icon from '@iconify/svelte'
  import { _ } from '$lib/i18n'
  import { WindowMinimise, WindowToggleMaximise, WindowIsMaximised, Environment, Quit } from '../../../../wailsjs/runtime/runtime'

  interface Props {
    onClose?: () => void
  }

  let { onClose }: Props = $props()

  let isMaximized = $state(false)
  let isHovering = $state(false)
  let isWindows = $state(false)

  $effect(() => {
    Environment().then((env) => { isWindows = env.platform === 'windows' })
    const sync = () => WindowIsMaximised().then((m) => { isMaximized = m })
    sync()
    window.addEventListener('resize', sync)
    return () => window.removeEventListener('resize', sync)
  })

  async function minimize() {
    await WindowMinimise()
  }

  async function toggleMaximize() {
    await WindowToggleMaximise()
    isMaximized = await WindowIsMaximised()
  }

  function close() {
    if (onClose) {
      onClose()
    } else {
      // For windows without custom onClose (e.g., composer), just quit directly
      Quit()
    }
  }
</script>

<header class="h-10 flex items-center justify-between bg-muted/50 border-b border-border select-none shrink-0">
  <!-- Drag region - left side with app title -->
  <div class="flex-1 flex items-center gap-2 px-3 h-full" style="--wails-draggable: drag">
    <Icon icon="mdi:email-fast-outline" class="w-5 h-5 text-primary" />
    <span class="text-sm font-medium text-foreground">Aerion</span>
  </div>

  {#if isWindows}
  <!-- Windows caption buttons, sized and coloured like the system ones -->
  <div class="flex items-stretch h-full" role="group" aria-label={$_('aria.windowControls')}>
    <button
      class="caption-btn"
      onclick={minimize}
      title={$_('window.minimize')}
      aria-label={$_('aria.minimizeWindow')}
    >
      <svg viewBox="0 0 10 10" aria-hidden="true"><line x1="0" y1="5.5" x2="10" y2="5.5" /></svg>
    </button>
    <button
      class="caption-btn"
      onclick={toggleMaximize}
      title={isMaximized ? $_('window.restore') : $_('window.maximize')}
      aria-label={isMaximized ? $_('aria.restoreWindow') : $_('aria.maximizeWindow')}
    >
      {#if isMaximized}
        <svg viewBox="0 0 10 10" aria-hidden="true">
          <rect x="0.5" y="2.5" width="7" height="7" />
          <polyline points="2.5,2.5 2.5,0.5 9.5,0.5 9.5,7.5 7.5,7.5" />
        </svg>
      {:else}
        <svg viewBox="0 0 10 10" aria-hidden="true"><rect x="0.5" y="0.5" width="9" height="9" /></svg>
      {/if}
    </button>
    <button
      class="caption-btn caption-close"
      onclick={close}
      title={$_('window.close')}
      aria-label={$_('aria.closeWindow')}
    >
      <svg viewBox="0 0 10 10" aria-hidden="true"><line x1="0" y1="0" x2="10" y2="10" /><line x1="10" y1="0" x2="0" y2="10" /></svg>
    </button>
  </div>
  {:else}
  <!-- Mac-style traffic light controls -->
  <div
    class="flex items-center gap-2 px-3 h-full"
    role="group"
    aria-label={$_('aria.windowControls')}
    onmouseenter={() => isHovering = true}
    onmouseleave={() => isHovering = false}
  >
    <!-- Minimize (yellow) -->
    <button
      class="w-3 h-3 rounded-full flex items-center justify-center transition-all bg-[#FEBC2E] hover:brightness-90 active:brightness-75"
      onclick={minimize}
      title={$_('window.minimize')}
      aria-label={$_('aria.minimizeWindow')}
    >
      {#if isHovering}
        <span class="text-[10px] font-bold text-black/60 leading-none">−</span>
      {/if}
    </button>

    <!-- Maximize/Restore (green) -->
    <button
      class="w-3 h-3 rounded-full flex items-center justify-center transition-all bg-[#28C840] hover:brightness-90 active:brightness-75"
      onclick={toggleMaximize}
      title={isMaximized ? $_('window.restore') : $_('window.maximize')}
      aria-label={isMaximized ? $_('aria.restoreWindow') : $_('aria.maximizeWindow')}
    >
      {#if isHovering}
        <span class="text-[10px] font-bold text-black/60 leading-none">+</span>
      {/if}
    </button>

    <!-- Close (red) -->
    <button
      class="w-3 h-3 rounded-full flex items-center justify-center transition-all bg-[#FF5F57] hover:brightness-90 active:brightness-75"
      onclick={close}
      title={$_('window.close')}
      aria-label={$_('aria.closeWindow')}
    >
      {#if isHovering}
        <span class="text-[10px] font-bold text-black/60 leading-none">×</span>
      {/if}
    </button>
  </div>
  {/if}
</header>

<style>
  .caption-btn {
    width: 46px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: hsl(var(--foreground));
    transition: background-color 0.1s;
  }
  .caption-btn svg {
    width: 10px;
    height: 10px;
    fill: none;
    stroke: currentColor;
    stroke-width: 1;
    shape-rendering: crispEdges;
  }
  .caption-btn:hover {
    background: color-mix(in srgb, currentColor 10%, transparent);
  }
  .caption-btn:active {
    background: color-mix(in srgb, currentColor 18%, transparent);
  }
  .caption-btn:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: -2px;
  }
  .caption-close:hover,
  .caption-close:active {
    background: #c42b1c;
    color: #fff;
  }
</style>
