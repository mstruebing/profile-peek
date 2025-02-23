// Create container for Elm app
const elmContainer = document.createElement('div');
elmContainer.id = 'elm-app-container';
document.body.appendChild(elmContainer);

// Inject the Elm script using executeScript
chrome.runtime.sendMessage({ type: 'INJECT_ELM' }, (_response) => {
    if (chrome.runtime.lastError) {
        console.error('Error injecting Elm:', chrome.runtime.lastError);
        return;
    }

    // Initialize Elm app once script is injected
    const Elm = window.Elm;
    if (Elm && Elm.Main) {
        Elm.Main.init({
            node: document.getElementById('elm-app-container'),
            flags: {
                url: window.location.href,
            }
        });
    } else {
        console.error('Elm.Main not found');
    }
});
