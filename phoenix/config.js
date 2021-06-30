Phoenix.set({ openAtLogin: true });

const hyper = ['ctrl', 'alt'];

Key.on("return", hyper, function () {
    Phoenix.log("moving window to center");
    const window = Window.focused();
    const screenFrame = window.screen().visibleFrame();
    window.setFrame({
        x: screenFrame.x + screenFrame.width * 1 / 4,
        y: screenFrame.y,
        width: screenFrame.width / 2,
        height: screenFrame.height,
    });
});

Key.on("left", hyper, function () {
    Phoenix.log("moving focused window to left quarter");
    const window = Window.focused();
    const screenFrame = window.screen().visibleFrame();
    window.setFrame({
        x: screenFrame.x,
        y: screenFrame.y,
        width: screenFrame.width / 4,
        height: screenFrame.height,
    });
});

Key.on("right", hyper, function () {
    Phoenix.log("moving focused window to right quarter");
    const window = Window.focused();
    const screenFrame = window.screen().visibleFrame();
    window.setFrame({
        x: screenFrame.x + screenFrame.width * 3 / 4,
        y: screenFrame.y,
        width: screenFrame.width / 4,
        height: screenFrame.height,
    });
});
