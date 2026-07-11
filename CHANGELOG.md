## [1.8.2](https://github.com/angristan/MacThrottle/compare/v1.8.1...v1.8.2) (2026-07-11)


### Bug Fixes

* release HID services array ([#35](https://github.com/angristan/MacThrottle/issues/35)) ([36308e2](https://github.com/angristan/MacThrottle/commit/36308e242a7541cc53abcf922bbff9fac8e2e4ff))

## [1.8.1](https://github.com/angristan/MacThrottle/compare/v1.8.0...v1.8.1) (2026-05-04)


### Bug Fixes

* restore release app signing ([#30](https://github.com/angristan/MacThrottle/issues/30)) ([4a2713e](https://github.com/angristan/MacThrottle/commit/4a2713e39fc0b96666ca5e39479ee576ee9e6207))

# [1.8.0](https://github.com/angristan/MacThrottle/compare/v1.7.4...v1.8.0) (2026-05-02)


### Features

* add manual update check ([#29](https://github.com/angristan/MacThrottle/issues/29)) ([1a5e957](https://github.com/angristan/MacThrottle/commit/1a5e957e8ea263d8062770478bc596742e4a1440))

## [1.7.4](https://github.com/angristan/MacThrottle/compare/v1.7.3...v1.7.4) (2026-04-29)


### Performance Improvements

* cache working SMC temperature keys ([09dc797](https://github.com/angristan/MacThrottle/commit/09dc797ddb48e042ac18bedb577244c930cca490))

## [1.7.3](https://github.com/angristan/MacThrottle/compare/v1.7.2...v1.7.3) (2026-01-01)


### Bug Fixes

* resolve UI latency when toggling Launch at Login ([ac88974](https://github.com/angristan/MacThrottle/commit/ac88974c3f32c7c9841b205442f387b41f7f2fc6)), closes [#16](https://github.com/angristan/MacThrottle/issues/16)

## [1.7.2](https://github.com/angristan/MacThrottle/compare/v1.7.1...v1.7.2) (2025-12-30)


### Bug Fixes

* release HID resources to prevent leak ([d38efde](https://github.com/angristan/MacThrottle/commit/d38efde9b077c02cf921c851dec0fb1d7418d061)), closes [#9](https://github.com/angristan/MacThrottle/issues/9)

## [1.7.1](https://github.com/angristan/MacThrottle/compare/v1.7.0...v1.7.1) (2025-12-29)


### Bug Fixes

* invalid temperature reading in release builds ([#11](https://github.com/angristan/MacThrottle/issues/11)) ([6476b5b](https://github.com/angristan/MacThrottle/commit/6476b5bac1043ec5245774a5527c4612f614012d))

# [1.7.0](https://github.com/angristan/MacThrottle/compare/v1.6.1...v1.7.0) (2025-12-29)


### Bug Fixes

* disable swiftlint line_length for long setting ([fdb5996](https://github.com/angristan/MacThrottle/commit/fdb5996a3152f98d003efdfe0271d468141a8aac))


### Features

* add option to show temperature in menu bar ([658a1f7](https://github.com/angristan/MacThrottle/commit/658a1f79ce9e7b03aa999ca7736c2238e298dd6c)), closes [#8](https://github.com/angristan/MacThrottle/issues/8)

## [1.6.1](https://github.com/angristan/MacThrottle/compare/v1.6.0...v1.6.1) (2025-12-29)


### Bug Fixes

* snap hover indicator to nearest data point on graph ([dbb46b7](https://github.com/angristan/MacThrottle/commit/dbb46b784e44e7d324bc4b05575e4d840198000e))

# [1.6.0](https://github.com/angristan/MacThrottle/compare/v1.5.2...v1.6.0) (2025-12-29)


### Bug Fixes

* add SMC temperature keys for M1/M2 Pro/Max/Ultra chips ([25e2bc4](https://github.com/angristan/MacThrottle/commit/25e2bc4db037d90442cb9f7b0aa98e290ffe89f9)), closes [#7](https://github.com/angristan/MacThrottle/issues/7)


### Features

* show temperature source in tooltip ([df02add](https://github.com/angristan/MacThrottle/commit/df02add21a83c051246b2c308446e049f96687f1))

## [1.5.2](https://github.com/angristan/MacThrottle/compare/v1.5.1...v1.5.2) (2025-12-29)


### Bug Fixes

* add missing temperature sensor keys for M1-M4 chips ([38543ab](https://github.com/angristan/MacThrottle/commit/38543ab6e612bd11d1851a99aa944b78e8c5159e)), closes [#7](https://github.com/angristan/MacThrottle/issues/7)

## [1.5.1](https://github.com/angristan/MacThrottle/compare/v1.5.0...v1.5.1) (2025-12-28)


### Bug Fixes

* add macOS 15 backward compatibility for glassEffect ([#2](https://github.com/angristan/MacThrottle/issues/2)) ([6102d5c](https://github.com/angristan/MacThrottle/commit/6102d5c41b1719e0612b7a8449ac13613846893b))

# [1.5.0](https://github.com/angristan/MacThrottle/compare/v1.4.1...v1.5.0) (2025-12-22)


### Features

* add fan speed graph with dual Y-axis ([753e7f4](https://github.com/angristan/MacThrottle/commit/753e7f4dfa8b36ece239b8e1307051c03abd339b))

## [1.4.1](https://github.com/angristan/MacThrottle/compare/v1.4.0...v1.4.1) (2025-12-19)


### Performance Improvements

* use drawingGroup for smoother graph hover on high refresh displays ([b85e55c](https://github.com/angristan/MacThrottle/commit/b85e55c65423a2a8385dcf40b0853a38e5bbd130))

# [1.4.0](https://github.com/angristan/MacThrottle/compare/v1.3.0...v1.4.0) (2025-12-18)


### Features

* add Launch at Login toggle ([ec9fd6c](https://github.com/angristan/MacThrottle/commit/ec9fd6c2489c153cd70da6d847eb6acb61d83e4a))

# [1.3.0](https://github.com/angristan/MacThrottle/compare/v1.2.3...v1.3.0) (2025-12-18)


### Features

* adopt Liquid Glass design and update to macOS 26 / Swift 6 ([d3bdcc3](https://github.com/angristan/MacThrottle/commit/d3bdcc36c47509846602cd5b9a188b594fd0a4b2))

## [1.2.3](https://github.com/angristan/MacThrottle/compare/v1.2.2...v1.2.3) (2025-12-18)


### Bug Fixes

* filter garbage SMC temperature readings in Release builds ([084039e](https://github.com/angristan/MacThrottle/commit/084039e4ab975b03016b9e36876e6079f0413ce6))

## [1.2.2](https://github.com/angristan/MacThrottle/compare/v1.2.1...v1.2.2) (2025-12-18)


### Bug Fixes

* improve history graph tooltip accuracy ([fbc2781](https://github.com/angristan/MacThrottle/commit/fbc27811804354704ce555e4c7cea0f1a71c7b17))

## [1.2.1](https://github.com/angristan/MacThrottle/compare/v1.2.0...v1.2.1) (2025-12-18)


### Bug Fixes

* remove horizontal line artifacts in history graph ([497566d](https://github.com/angristan/MacThrottle/commit/497566d81e43cd5ab4437bbe58d4557fd4be4d97))
* silence unused result warning for notify_cancel ([7fa7d80](https://github.com/angristan/MacThrottle/commit/7fa7d80dad866649bf04d650a07c79c32fbe1504))

# [1.2.0](https://github.com/angristan/MacThrottle/compare/v1.1.0...v1.2.0) (2025-12-18)


### Features

* remove helper daemon, read thermal pressure directly ([20f3861](https://github.com/angristan/MacThrottle/commit/20f3861073634b7c42fc427eb151c07ba2bfe2c6))

# [1.1.0](https://github.com/angristan/MacThrottle/compare/v1.0.0...v1.1.0) (2025-12-18)


### Features

* add cpu temperature monitoring and history tracking ([c356c75](https://github.com/angristan/MacThrottle/commit/c356c75b85f04a6da6f2f073042c159ed7a49304))

# 1.0.0 (2025-12-16)


### Bug Fixes

* clarify helper status message ([edd177e](https://github.com/angristan/MacThrottle/commit/edd177e584d0c8d5c8df6f7cdd82be37a881a3f5))


### Features

* add app icon and About window ([00530c8](https://github.com/angristan/MacThrottle/commit/00530c8345a156d9d6f525d002dfa49bb90f1752))
* add colored fill to thermometer icon ([6769c3c](https://github.com/angristan/MacThrottle/commit/6769c3cbd9a9f48b52500738e19d3ab1e236a834))
* add configurable notification settings ([89327c9](https://github.com/angristan/MacThrottle/commit/89327c92ef95b4a44cdc656c8b3d2cacca349625))
* color thermal pressure text in menu ([1229b90](https://github.com/angristan/MacThrottle/commit/1229b905f058abfc192a44df96e4112b98bbf43b))
* init ([3400c0d](https://github.com/angristan/MacThrottle/commit/3400c0d1e02d85b68c4de5698b0580d0ef073a3d))
* use monochromatic menu bar icon with shape-based states ([03a1db5](https://github.com/angristan/MacThrottle/commit/03a1db5f6b76342c7a1fe4678c670d953f612759))


### Performance Improvements

* increase helper polling interval to 10 seconds ([fd2e968](https://github.com/angristan/MacThrottle/commit/fd2e9681fb92dce56cf3bb04ec1ab0a52ec16a78))
