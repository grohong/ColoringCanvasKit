# ColoringCanvasKit

**ColoringCanvasKit**은 iOS 애플리케이션에서 간단하게 사용할 수 있는 컬러링 캔버스 라이브러리입니다. 이 라이브러리는 사용자에게 [Floodfill 알고리즘](https://ko.wikipedia.org/wiki/%ED%94%8C%EB%9F%AC%EB%93%9C_%ED%95%84)을 이용하여 그림의 영역에만 색칠을 할 수 있는 기능을 제공합니다. UIKit과 SwiftUI를 모두 지원하여 다양한 개발 환경에서 활용할 수 있습니다.

## 주요 기능

- **다양한 브러시 스타일**: 선의 두께와 스타일을 설정할 수 있습니다.
- **Floodfill 색칠 기능**: **Floodfill 알고리즘**을 사용하여 닫힌 영역 내에서만 색을 채울 수 있습니다. 이를 통해 사용자들이 기존에 그려진 선을 넘지 않고 색칠할 수 있습니다.
- **Undo/Redo 기능**: 실수한 부분을 쉽게 되돌릴 수 있습니다.

| Autograph | Brush | Crayon | Fill |
|------|-----|------|-------|
|![Autograph](./images/RPReplay_Final1725321321.gif)|![Brush](./images/RPReplay_Final1725321331.gif)|![Crayon](./images/RPReplay_Final1725321346.gif)|![Fill](./images/RPReplay_Final1725321362.gif)|

## 설치

ColoringCanvasKit은 Swift Package Manager(SPM)를 통해 설치할 수 있습니다.

### Swift Package Manager(SPM)

1. Xcode 프로젝트를 열고, `File > Swift Packages > Add Package Dependency...`를 선택합니다.
2. 아래의 URL을 입력합니다
    - https://github.com/grohong/ColoringCanvasKit.git
3. `main` 브랜치를 선택한 후, `Next`를 클릭합니다.
4. 프로젝트에 패키지를 추가할 타겟을 선택한 후, `Finish`를 클릭합니다.

## 사용 방법

ColoringCanvasKit을 사용하는 방법은 매우 간단합니다. [Example 파일](https://github.com/grohong/ColoringCanvasKit/tree/main/ColoringCanvasKitExample)을 참고하세요.

### SwiftUI

```swift
import SwiftUI
import ColoringCanvasKit

struct ContentView: View {

    let canvasImage: CanvasImage
    @StateObject private var viewModel = CanvasViewModel()

    var body: some View {
        VStack {
            ColoringCanvasViewRepresentable(
                canvasImage: canvasImage,
                viewModel: viewModel
            )

            Slider(
                value: $viewModel.brushSize,
                in: 1...100,
                label: { Text("Brush Size") }
            )

            ColorPicker("Select Color", selection: Binding(
                get: { Color(viewModel.color) },
                set: { viewModel.color = UIColor($0) }
            ))
            .padding()

            Picker("Tool", selection: $viewModel.toolKind) {
                Text("Autograph").tag(ToolKind.autograph)
                Text("Brush").tag(ToolKind.brush)
                Text("Crayon").tag(ToolKind.crayon)
                Text("fill").tag(ToolKind.fill)
                Text("Eraser").tag(ToolKind.eraser)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            HStack {
                Button(action: {
                    viewModel.backward()
                }) {
                    Text("Back")
                }
                .disabled(!viewModel.isBackwardEnabled)

                Button(action: {
                    viewModel.forward()
                }) {
                    Text("forwarod")
                }
                .disabled(!viewModel.isForwardEnabled)
            }
        }
        .padding()
    }
}
```

## 라이선스

ColoringCanvasKit은 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](https://github.com/grohong/ColoringCanvasKit/blob/main/LICENSE) 파일을 참조하세요.

