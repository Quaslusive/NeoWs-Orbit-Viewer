function loadSpaceKitOrbit() {
  const spacekit = new Spacekit.Scene(document.getElementById('spacekit-container'), {
    basePath: 'https://typpo.github.io/spacekit/src',
    startDate: new Date(),
  });

  spacekit.createObject('earth');

  // Example orbit
  spacekit.createObject('myAsteroid', {
    ephem: {
      a: 2.77,
      e: 0.075,
      i: 10.593,
      om: 80.305,
      w: 73.597,
      ma: 0,
    },
  });
}
