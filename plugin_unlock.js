(() => {
  const runtimeKey = "__codexPluginUnlockLiteRuntime";
  if (window[runtimeKey]?.scan) {
    window[runtimeKey].scan();
    return;
  }

  const selectors = {
    pluginNavButton: 'nav[role="navigation"] button.h-token-nav-row.w-full, nav[role="navigation"] [role="button"]',
    pluginSvgPath: 'svg path[d^="M7.94562 14.0277"]',
    disabledInstallButton: 'button:disabled.w-full.justify-center, [role="button"][aria-disabled="true"].cursor-not-allowed, [aria-disabled="true"][data-testid*="install"]',
  };
  const installLabelPattern = /^(安装|安裝|Install|强制安装|強制安裝)(\s|$)/i;
  const unavailableLabelPattern = /App unavailable|应用不可用|應用程式無法使用/i;

  function reactFiberFrom(element) {
    const fiberKey = Object.keys(element || {}).find((key) => key.startsWith("__reactFiber"));
    return fiberKey ? element[fiberKey] : null;
  }

  function authContextValueFrom(element) {
    for (let fiber = reactFiberFrom(element); fiber; fiber = fiber.return) {
      for (const value of [fiber.memoizedProps?.value, fiber.pendingProps?.value]) {
        if (value && typeof value === "object" && typeof value.setAuthMethod === "function" && "authMethod" in value) {
          return value;
        }
      }
    }
    return null;
  }

  function spoofChatGPTAuthMethod(element) {
    const auth = authContextValueFrom(element);
    if (!auth || auth.authMethod === "chatgpt") return false;
    auth.setAuthMethod("chatgpt");
    return true;
  }

  function pluginEntryButton() {
    const byIcon = document.querySelector(`${selectors.pluginNavButton} ${selectors.pluginSvgPath}`)?.closest("button, [role='button']");
    if (byIcon) return byIcon;
    return Array.from(document.querySelectorAll(selectors.pluginNavButton)).find((button) => {
      const text = (button.textContent || "").replace(/\s+/g, " ").trim();
      return /^(插件|外挂程式|外掛程式|Plugins)(\s*-\s*.*)?$/i.test(text);
    }) || null;
  }

  function updateReactDisabledState(element) {
    const key = Object.keys(element || {}).find((name) => name.startsWith("__reactProps"));
    if (!key) return;
    const props = element[key];
    if (!props || typeof props !== "object") return;
    props.disabled = false;
    props["aria-disabled"] = false;
  }

  function labelUnlockedPluginEntry(button) {
    const textNodes = Array.from(button.querySelectorAll("span, div"))
      .reverse()
      .flatMap((node) => Array.from(node.childNodes))
      .filter((node) => node.nodeType === Node.TEXT_NODE);
    const matched = textNodes.find((node) => /^(插件|Plugins)(\s*-\s*(已解锁|Unlocked))?$/i.test((node.nodeValue || "").trim()));
    if (!matched) return;
    const current = (matched.nodeValue || "").trim();
    matched.nodeValue = /^Plugins/i.test(current) ? "Plugins - Unlocked" : "插件 - 已解锁";
  }

  function enablePluginEntry() {
    const pluginButton = pluginEntryButton();
    if (!pluginButton) return false;
    spoofChatGPTAuthMethod(pluginButton);
    pluginButton.disabled = false;
    pluginButton.removeAttribute("disabled");
    pluginButton.setAttribute("aria-disabled", "false");
    pluginButton.classList.remove("disabled", "opacity-50", "cursor-not-allowed", "pointer-events-none");
    pluginButton.style.display = "";
    pluginButton.style.pointerEvents = "auto";
    updateReactDisabledState(pluginButton);
    labelUnlockedPluginEntry(pluginButton);
    if (pluginButton.dataset.codexPluginUnlockLiteBound !== "true") {
      pluginButton.dataset.codexPluginUnlockLiteBound = "true";
      pluginButton.addEventListener("click", () => spoofChatGPTAuthMethod(pluginButton), true);
    }
    return true;
  }

  function installButtonLabel(button) {
    return (button.textContent || "").replace(/\s+/g, " ").trim();
  }

  function isInstallLabel(text) {
    return installLabelPattern.test(text || "");
  }

  function forcedInstallLabelFrom(currentLabel) {
    if (/安裝/.test(currentLabel)) return "強制安裝";
    if (/安装/.test(currentLabel)) return "强制安装";
    if (/install/i.test(currentLabel)) return "Force Install";
    return "强制安装";
  }

  function appearsInConversation(element) {
    return !!element.closest?.('[data-message-author-role], [data-testid="conversation-turn"], [data-testid^="conversation-turn"], main .prose');
  }

  function hasUnavailableBadgeNearby(element) {
    let node = element;
    for (let depth = 0; node && depth < 7; depth += 1) {
      const text = (node.textContent || "").replace(/\s+/g, " ").trim();
      if (unavailableLabelPattern.test(text)) return true;
      node = node.parentElement;
    }
    return false;
  }

  function buttonLooksBlocked(button) {
    const computed = getComputedStyle(button);
    const className = String(button.className || "");
    return button.disabled
      || button.hasAttribute("disabled")
      || button.getAttribute("aria-disabled") === "true"
      || /disabled|opacity-50|cursor-not-allowed|pointer-events-none/.test(className)
      || computed.pointerEvents === "none";
  }

  function unblockAncestorChain(button) {
    let node = button.parentElement;
    let depth = 0;
    while (node && depth < 12) {
      node.classList?.remove?.("disabled", "opacity-50", "cursor-not-allowed", "pointer-events-none");
      if (node.getAttribute?.("aria-disabled") === "true") {
        node.setAttribute("aria-disabled", "false");
      }
      if (node.style?.pointerEvents === "none") node.style.pointerEvents = "auto";
      if (node.style?.opacity && Number.parseFloat(node.style.opacity) < 1) node.style.opacity = "1";
      updateReactDisabledState(node);
      node = node.parentElement;
      depth += 1;
    }
  }

  function unblockButtonElement(button) {
    button.disabled = false;
    button.removeAttribute("disabled");
    button.removeAttribute("aria-disabled");
    button.classList.remove("disabled", "opacity-50", "cursor-not-allowed", "pointer-events-none");
    button.style.pointerEvents = "auto";
    button.tabIndex = 0;
    updateReactDisabledState(button);
  }

  function labelForcedInstallButton(button) {
    const currentLabel = installButtonLabel(button);
    const forcedLabel = forcedInstallLabelFrom(currentLabel);
    const directTextNode = Array.from(button.childNodes).find((node) => {
      if (node.nodeType !== Node.TEXT_NODE) return false;
      return isInstallLabel((node.nodeValue || "").replace(/\s+/g, " ").trim());
    });
    if (directTextNode) {
      directTextNode.nodeValue = forcedLabel;
      return;
    }
    const labelContainer = button.querySelector("span, div");
    if (labelContainer && isInstallLabel(installButtonLabel(labelContainer))) {
      labelContainer.textContent = forcedLabel;
    }
  }

  function pluginInstallCandidates() {
    const broadCandidates = Array.from(document.querySelectorAll("button, [role='button']"))
      .filter((element) => !appearsInConversation(element))
      .filter((element) => isInstallLabel(installButtonLabel(element)));
    const strictDisabled = Array.from(document.querySelectorAll(selectors.disabledInstallButton))
      .filter((element) => !appearsInConversation(element));
    return Array.from(new Set([...strictDisabled, ...broadCandidates]));
  }

  function unblockPluginInstallButtons() {
    let changed = 0;
    const candidates = pluginInstallCandidates();
    candidates.forEach((button) => {
      const label = installButtonLabel(button);
      if (!isInstallLabel(label)) return;
      if (!buttonLooksBlocked(button) && !hasUnavailableBadgeNearby(button)) return;
      unblockButtonElement(button);
      unblockAncestorChain(button);
      labelForcedInstallButton(button);
      changed += 1;
    });
    return changed > 0;
  }

  function scan() {
    try {
      enablePluginEntry();
      unblockPluginInstallButtons();
      window.__codexPluginUnlockLiteLastError = "";
    } catch (error) {
      window.__codexPluginUnlockLiteLastError = String(error?.stack || error);
    }
  }

  function isRelevantNode(node) {
    if (node.nodeType !== Node.ELEMENT_NODE) return false;
    if (node.matches?.(selectors.pluginNavButton)) return true;
    if (node.matches?.(selectors.disabledInstallButton)) return true;
    if (node.querySelector?.(selectors.pluginNavButton)) return true;
    if (node.querySelector?.(selectors.disabledInstallButton)) return true;
    const text = (node.textContent || "").trim();
    return text.includes("Plugins")
      || text.includes("插件")
      || text.includes("外挂程式")
      || text.includes("外掛程式")
      || text.includes("App unavailable")
      || text.includes("应用不可用");
  }

  function shouldScheduleScan(mutations) {
    if (!mutations || mutations.length === 0) return true;
    return mutations.some((mutation) => {
      if (isRelevantNode(mutation.target)) return true;
      return [...Array.from(mutation.addedNodes), ...Array.from(mutation.removedNodes)].some(isRelevantNode);
    });
  }

  function scheduleScan(mutations) {
    if (!shouldScheduleScan(mutations)) return;
    if (window.__codexPluginUnlockLitePending) return;
    window.__codexPluginUnlockLitePending = true;
    clearTimeout(window.__codexPluginUnlockLiteTimer);
    window.__codexPluginUnlockLiteTimer = setTimeout(() => {
      window.__codexPluginUnlockLitePending = false;
      scan();
    }, 150);
  }

  window.__codexPluginUnlockLiteObserver?.disconnect();
  window.__codexPluginUnlockLiteObserver = new MutationObserver(scheduleScan);
  window.__codexPluginUnlockLiteObserver.observe(document.body || document.documentElement, { childList: true, subtree: true, attributes: true });

  window[runtimeKey] = { scan };
  scan();
})();
