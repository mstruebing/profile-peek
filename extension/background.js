chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'INJECT_ELM') {
    chrome.scripting.executeScript({
      target: { tabId: sender.tab.id },
      files: ['elm.js']
    })
    .then(() => sendResponse(true))
    .catch((err) => {
      console.error('Error injecting elm.js:', err);
      sendResponse(false);
    });
    return true; // Required for async response
  }
}); 