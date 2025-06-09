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
        const app = Elm.Main.init({
            node: document.getElementById('elm-app-container'),
            flags: {
                url: window.location.href,
            }
        });

        app.ports.requestLocalStorageItem.subscribe((key) => {
            const value = localStorage.getItem(key);
            if (value) {
                app.ports.receiveLocalStorageItem.send(value);
            }
        })

        app.ports.setLocalStorageItem.subscribe(([key, value]) => {
            localStorage.setItem(key, JSON.stringify(value));
        });

        setTimeout(() => {
            document.querySelectorAll(".profile-peek-icon").forEach((icon) => {
                icon.addEventListener("mouseover", (e) => {
                    e.target.style.scale = "1.5";
                })

                icon.addEventListener("mouseout", (e) => {
                    e.target.style.scale = "1";
                })
            })
        }, 1000)
    } else {
        console.error('Elm.Main not found');
    }
});
