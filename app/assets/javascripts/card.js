// This JS code resizes a font to fit the height of its container.

window.addEventListener('DOMContentLoaded', (event) => {
    fitin = document.querySelector('.fitin');
    fitin_inner = document.querySelector('div .heading-text');

    while (fitin_inner.offsetHeight > fitin.offsetHeight) {
        fontStyling = window
            .getComputedStyle(fitin_inner, null)
            .getPropertyValue('font-size');
        fontSize = parseFloat(fontStyling);
        fitin_inner.style.fontSize = fontSize - 1 + 'px';
    }

});
