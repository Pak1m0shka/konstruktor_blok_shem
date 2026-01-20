import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import myObrabotka
import QtQuick.Dialogs
import Qt.labs.platform 1.1

Window {
    id: main
    width: 1000
    height: 700
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: qsTr("Построй алгоритм по задаче")

    // Свойства темы
    property bool isDarkTheme: true
    property color backgroundColor: isDarkTheme ? "#121212" : "#f5f7fa"
    property color panelColor: isDarkTheme ? "#1e1e1e" : "#ffffff"
    property color textColor: isDarkTheme ? "#e0e0e0" : "#333333"
    property color borderColor: isDarkTheme ? "#424242" : "#e0e0e0"
    property color buttonColor: isDarkTheme ? "#424242" : "#e0e0e0"
    property color hoverColor: isDarkTheme ? "#616161" : "#d0d0d0"
    property color pressedColor: isDarkTheme ? "#757575" : "#bdbdbd"

    color: backgroundColor
    property Item activeContainer: container
    property Item activeToggle: null
    property string selectedBlockType: "действие"
    property bool debugMode: false
    property int currentDebugBlockId: -1
    property bool canStepBack: false
    property bool canStepForward: true
    property int blockIdCounter: 0
    property int debugStartBlockId: -1

    Obrabotka {
        id: myObrabotka
        onNeedUserInput: () => {
            console.log("QML: Получен запрос на ввод")
            otvet.text = otvet.text + "\n" + "QML: Получен запрос на ввод"
        }
        onInputProcessed: (result) => {
            console.log("ответ вернулся")
        }
        onVivod: (otvet_cpp) => {
            console.log("ответ есть")
            console.log(otvet_cpp)
            otvet.text = otvet.text + "\n" + otvet_cpp
        }
        onDebugging_peremennie: (peremennie) => {
            console.log("Получены переменные от C++ для отображения")
            console.log("Данные (peremennie - QVariantMap):", peremennie)

            variablesModel.clear();

            if (peremennie && typeof peremennie === 'object') {
                var keys = Object.keys(peremennie);
                for (var i = 0; i < keys.length; i++) {
                    var name = keys[i];
                    var value = peremennie[name];
                    console.log("Добавляем переменную:", name, "=", value);
                    variablesModel.append({ name: name, value: String(value) });
                }
            } else {
                console.warn("peremennie не является объектом:", peremennie);
            }
        }

        onHighlightBlock: (blockId) => {
            console.log("Получен сигнал highlightBlock с ID:", blockId);
            currentDebugBlockId = blockId;
        }

        onDebugHistoryChanged: (canStepBack, canStepForward) => {
            console.log("История отладки изменилась, можно шагать назад:", canStepBack, "можно шагать вперед:", canStepForward);
            main.canStepBack = canStepBack;
            main.canStepForward = canStepForward;
        }

        onDebugFinished: () => {
            console.log("Отладка завершена");
            main.debugMode = false;
            variablesModel.clear();
            currentDebugBlockId = -1;
        }

        onAlgorithmLoaded: (algorithm) => {
            console.log("Получен сигнал algorithmLoaded, количество блоков:", algorithm.length)
            main.debugStartBlockId = -1
            if (algorithm && algorithm.length > 0) {
                loadAlgorithm(algorithm, container)
                information_save.text = "Алгоритм успешно загружен"
                information_save.open()
            }
        }

        onErrorOccurred: (errorMessage) => {
            console.log("Ошибка при загрузке:", errorMessage)
            errorDialog.text = errorMessage
            errorDialog.open()
        }
    }

    property string userInputResult: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // === Верхняя панель кнопок (1 ряд) ===
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 5

            // Кнопка переключения темы
            Button {
                id: themeButton
                text: main.isDarkTheme ? "☀️" : "🌙"
                hoverEnabled: true
                Layout.preferredHeight: 50
                Layout.preferredWidth: 60

                background: Rectangle {
                    color: "transparent"
                    border.color: main.borderColor
                    border.width: 2
                    radius: 8

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: main.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 20
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: {
                    main.isDarkTheme = !main.isDarkTheme
                }
            }

            Button {
                id: debugButton
                text: main.debugMode ? "Закончить отладку" : "Отладка"
                hoverEnabled: true
                Shortcut {
                     sequence: "F6"
                     onActivated: {
                         if (main.debugMode) {
                             myObrabotka.stopDebugging();
                         } else {
                             main.debugMode = true;
                             console.log("Режим отладки включен");
                             collectData(2);
                         }
                     }
                }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 180

                background: Rectangle {
                    id: debugBg
                    color: {
                        if (debugButton.pressed) return Qt.darker("#9c27b0", 1.2)
                        else if (debugButton.hovered) return Qt.lighter("#9c27b0", 1.1)
                        else return main.debugMode ? "#9c27b0" : "#ab47bc"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: {
                    if (main.debugMode) {
                        console.log("Нажата кнопка 'Закончить отладку'");
                        myObrabotka.stopDebugging();
                    } else {
                        main.debugMode = true;
                        console.log("Режим отладки включен");
                        collectData(2);
                    }
                }
            }

            Button {
                id: runButton
                text: "Запуск"
                hoverEnabled: true
                onClicked: collectData(1)
                Shortcut { sequence: "F1"; onActivated: collectData(1) }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150

                background: Rectangle {
                    id: runBg
                    color: {
                        if (runButton.pressed) return Qt.darker("#4caf50", 1.2)
                        else if (runButton.hovered) return Qt.lighter("#4caf50", 1.1)
                        else return "#4caf50"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: saveButton
                text: "Сохранить"
                hoverEnabled: true
                Shortcut { sequence: "F2"; onActivated: saveFileDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150

                background: Rectangle {
                    id: saveBg
                    color: {
                        if (saveButton.pressed) return Qt.darker("#42a5f5", 1.2)
                        else if (saveButton.hovered) return Qt.lighter("#42a5f5", 1.1)
                        else return "#42a5f5"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: saveFileDialog.open()
            }

            Button {
                id: openButton
                text: "Открыть"
                hoverEnabled: true
                Shortcut { sequence: "F3"; onActivated: openFileDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150

                background: Rectangle {
                    id: openBg
                    color: {
                        if (openButton.pressed) return Qt.darker("#42a5f5", 1.2)
                        else if (openButton.hovered) return Qt.lighter("#42a5f5", 1.1)
                        else return "#42a5f5"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: openFileDialog.open()
            }

            Button {
                id: newAlgButton
                text: "Новый алгоритм"
                hoverEnabled: true
                Shortcut { sequence: "F4"; onActivated: newAlgorithmDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 180

                background: Rectangle {
                    id: newAlgBg
                    color: {
                        if (newAlgButton.pressed) return Qt.darker("#42a5f5", 1.2)
                        else if (newAlgButton.hovered) return Qt.lighter("#42a5f5", 1.1)
                        else return "#42a5f5"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: newAlgorithmDialog.open()
            }

            Button {
                id: helpButton
                text: "Справка"
                hoverEnabled: true
                Shortcut { sequence: "F5"; onActivated: helpDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150

                background: Rectangle {
                    id: helpBg
                    color: {
                        if (helpButton.pressed) return Qt.darker("#ab47bc", 1.2)
                        else if (helpButton.hovered) return Qt.lighter("#ab47bc", 1.1)
                        else return "#ab47bc"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }

                onClicked: helpDialog.open()
            }
        }

        // === Панель кнопок спавна (2 ряд) ===
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 5

            ComboBox {
                id: blockTypeSelector
                enabled: !main.debugMode
                Layout.preferredWidth: 250
                Layout.preferredHeight: 50
                model: ListModel {
                    id: blockTypeModel
                    ListElement { type: "ввод"; displayName: "Ввод" }
                    ListElement { type: "вывод"; displayName: "Вывод" }
                    ListElement { type: "действие"; displayName: "Действие" }
                    ListElement { type: "счетчик"; displayName: "Счетчик" }
                    ListElement { type: "предусл"; displayName: "Предусловие" }
                    ListElement { type: "постусл"; displayName: "Постусловие" }
                    ListElement { type: "усл"; displayName: "Условие" }
                    ListElement { type: "начало"; displayName: "Начало" }
                    ListElement { type: "конец"; displayName: "Конец" }
                }
                onCurrentIndexChanged: {
                    if (blockTypeSelector.currentIndex >= 0 && blockTypeSelector.currentIndex < blockTypeSelector.model.count) {
                        main.selectedBlockType = blockTypeSelector.model.get(blockTypeSelector.currentIndex).type;
                        console.log("Выбран тип блокa (по модели):", main.selectedBlockType);
                    }
                }
                currentIndex: 2
                background: Rectangle {
                    id: comboBg
                    color: main.isDarkTheme ? "#2d2d2d" : "#ffffff"
                    border.color: blockTypeSelector.hovered ? "#42a5f5" : main.borderColor
                    border.width: 2
                    radius: 8

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }
                }
                contentItem: Row {
                    leftPadding: 10
                    spacing: 5
                    Loader {
                        id: selectedBlockMiniShapeLoader
                        width: 25
                        height: 25
                        sourceComponent: miniBlockShapeItem
                        onLoaded: {
                            item.blockType = main.selectedBlockType;
                        }
                        Connections {
                            target: main
                            function onSelectedBlockTypeChanged() {
                                if (selectedBlockMiniShapeLoader.item) {
                                    selectedBlockMiniShapeLoader.item.blockType = main.selectedBlockType;
                                }
                            }
                        }
                    }
                    Text {
                        text: {
                            var currentIdx = blockTypeSelector.currentIndex;
                            if (currentIdx >= 0 && currentIdx < blockTypeSelector.model.count) {
                                return blockTypeSelector.model.get(currentIdx).displayName || "";
                            }
                            return "";
                        }
                        color: main.textColor
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 18
                        font.bold: true
                    }
                }
                delegate: ItemDelegate {
                    id: delegateItem
                    width: parent.width
                    height: 45
                    hoverEnabled: true
                    highlighted: ListView.isCurrentItem
                    background: Rectangle {
                        color: delegateItem.highlighted ? (main.isDarkTheme ? "#424242" : "#e3f2fd") :
                                (delegateItem.hovered ? (main.isDarkTheme ? "#2d2d2d" : "#f5f5f5") :
                                (main.isDarkTheme ? "#2d2d2d" : "#ffffff"))
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    contentItem: Row {
                        spacing: 5
                        leftPadding: 5
                        Loader {
                            width: 30
                            height: 30
                            sourceComponent: miniBlockShapeItem
                            onLoaded: {
                                item.blockType = model.type;
                            }
                        }
                        Text {
                            text: model.displayName
                            color: main.textColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5
                            font.pixelSize: 18
                        }
                    }
                }
                indicator: Canvas {
                    x: parent.width - width - 10
                    y: parent.height / 2 - height / 2
                    width: 12
                    height: 8
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.fillStyle = main.textColor
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width / 2, height)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }

            // Кнопки с фигурами блоков
            Button {
                id: inputBtn
                text: "Ввод"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("ввод")
                Shortcut { sequence: "F7"; onActivated: if(enabled) createBlock("ввод") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100

                background: Rectangle {
                    id: inputBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var s = h * 0.2
                            ctx.beginPath()
                            ctx.moveTo(s, 0)
                            ctx.lineTo(w, 0)
                            ctx.lineTo(w - s, h)
                            ctx.lineTo(0, h)
                            ctx.closePath()
                            var fillColor = inputBtn.pressed ? Qt.darker("#ba68c8", 1.2) :
                                            (inputBtn.hovered ? Qt.lighter("#ba68c8", 1.1) : "#ba68c8")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = inputBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Ввод"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: outputBtn
                text: "Вывод"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("вывод")
                Shortcut { sequence: "F8"; onActivated: if(enabled) createBlock("вывод") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100

                background: Rectangle {
                    id: outputBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var s = h * 0.2
                            ctx.beginPath()
                            ctx.moveTo(s, 0)
                            ctx.lineTo(w, 0)
                            ctx.lineTo(w - s, h)
                            ctx.lineTo(0, h)
                            ctx.closePath()
                            var fillColor = outputBtn.pressed ? Qt.darker("#4db6ac", 1.2) :
                                            (outputBtn.hovered ? Qt.lighter("#4db6ac", 1.1) : "#4db6ac")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = outputBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Вывод"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: actionBtn
                text: "Действие"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("действие")
                Shortcut { sequence: "F9"; onActivated: if(enabled) createBlock("действие") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: actionBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var fillColor = actionBtn.pressed ? Qt.darker("#64b5f6", 1.2) :
                                            (actionBtn.hovered ? Qt.lighter("#64b5f6", 1.1) : "#64b5f6")
                            ctx.fillStyle = fillColor
                            ctx.fillRect(0, 0, w, h)
                            ctx.strokeStyle = actionBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.strokeRect(0, 0, w, h)
                        }
                    }

                    Text {
                        text: "Действие"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: counterBtn
                text: "Счетчик"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("счетчик")
                Shortcut { sequence: "F10"; onActivated: if(enabled) createBlock("счетчик") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: counterBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var hex = h * 0.3
                            ctx.beginPath()
                            ctx.moveTo(hex, 0)
                            ctx.lineTo(w - hex, 0)
                            ctx.lineTo(w, h / 2)
                            ctx.lineTo(w - hex, h)
                            ctx.lineTo(hex, h)
                            ctx.lineTo(0, h / 2)
                            ctx.closePath()
                            var fillColor = counterBtn.pressed ? Qt.darker("#ef5350", 1.2) :
                                            (counterBtn.hovered ? Qt.lighter("#ef5350", 1.1) : "#ef5350")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = counterBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Счетчик"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: precondBtn
                text: "Предусл"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("предусл")
                Shortcut { sequence: "F11"; onActivated: if(enabled) createBlock("предусл") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: precondBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.moveTo(cx, 5)
                            ctx.lineTo(w - 5, cy)
                            ctx.lineTo(cx, h - 5)
                            ctx.lineTo(5, cy)
                            ctx.closePath()
                            var fillColor = precondBtn.pressed ? Qt.darker("#ffb74d", 1.2) :
                                            (precondBtn.hovered ? Qt.lighter("#ffb74d", 1.1) : "#ffb74d")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = precondBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Предусл"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: postcondBtn
                text: "Постусл"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("постусл")
                Shortcut { sequence: "F12"; onActivated: if(enabled) createBlock("постусл") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: postcondBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.moveTo(cx, 5)
                            ctx.lineTo(w - 5, cy)
                            ctx.lineTo(cx, h - 5)
                            ctx.lineTo(5, cy)
                            ctx.closePath()
                            var fillColor = postcondBtn.pressed ? Qt.darker("#ce93d8", 1.2) :
                                            (postcondBtn.hovered ? Qt.lighter("#ce93d8", 1.1) : "#ce93d8")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = postcondBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Постусл"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: condBtn
                text: "Усл"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("усл")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100

                background: Rectangle {
                    id: condBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.moveTo(cx, 5)
                            ctx.lineTo(w - 5, cy)
                            ctx.lineTo(cx, h - 5)
                            ctx.lineTo(5, cy)
                            ctx.closePath()
                            var fillColor = condBtn.pressed ? Qt.darker("#81c784", 1.2) :
                                            (condBtn.hovered ? Qt.lighter("#81c784", 1.1) : "#81c784")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = condBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Усл"
                        anchors.centerIn: parent
                        color: main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: startBtn
                text: "Начало"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("начало")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: startBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.ellipse(5, 5, w - 10, h - 10)
                            ctx.closePath()
                            var fillColor = startBtn.pressed ? Qt.darker("#64b5f6", 1.2) :
                                            (startBtn.hovered ? Qt.lighter("#64b5f6", 1.1) : "#64b5f6")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = startBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.stroke()
                            ctx.fillStyle = main.textColor
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Начало", cx, cy)
                        }
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            Button {
                id: endBtn
                text: "Конец"
                enabled: !main.debugMode
                hoverEnabled: true
                onClicked: createBlock("конец")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120

                background: Rectangle {
                    id: endBtnBg
                    color: "transparent"
                    radius: 8
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.ellipse(5, 5, w - 10, h - 10)
                            ctx.closePath()
                            var fillColor = endBtn.pressed ? Qt.darker("#ffb74d", 1.2) :
                                            (endBtn.hovered ? Qt.lighter("#ffb74d", 1.1) : "#ffb74d")
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = endBtn.hovered ? "#e0e0e0" : "#e0e0e0"
                            ctx.stroke()
                            ctx.fillStyle = main.textColor
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Конец", cx, cy)
                        }
                    }
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }

        // === Область алгоритма и Панель отладки ===
        Row {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // === Область алгоритма ===
            Rectangle {
                id: algorithmArea
                width: main.debugMode ? (parent.width - debugPanel.width - parent.spacing) : parent.width
                height: parent.height
                border.color: main.activeContainer === container ? "#9c27b0" : main.borderColor
                border.width: 2
                radius: 5
                color: main.panelColor

                Behavior on border.color {
                    ColorAnimation { duration: 300 }
                }

                Flickable {
                    id: prokrutka
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    contentHeight: container.height
                    contentWidth: container.width
                    flickableDirection: Flickable.HorizontalAndVerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: container
                        width: Math.max(prokrutka.width, childrenRect.width)
                        spacing: 10
                        padding: 5
                    }

                    Button {
                        id: mainActivateBtn
                        enabled: !main.debugMode
                        hoverEnabled: true
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 5
                        width: 35
                        height: 35
                        text: "A"

                        background: Rectangle {
                            id: mainActivateBg
                            color: {
                                if (mainActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                else if (mainActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                else return main.activeContainer === container ? "#9c27b0" : main.buttonColor
                            }
                            radius: width / 2

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                            font.bold: true
                        }

                        scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                        opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        onClicked: {
                            if (main.activeContainer === container) {
                                main.activeContainer = null
                                console.log("Основная область деактивирована")
                            } else {
                                main.activeContainer = container
                                console.log("Основная область активирована")
                            }
                        }
                    }

                    TapHandler {
                        enabled: !main.debugMode
                        onTapped: {
                            if (main.activeContainer === container) {
                                createBlock(main.selectedBlockType)
                                console.log("Создан блок типа:", main.selectedBlockType, "по клику")
                            }
                        }
                    }
                }
            }

            // === Панель отладки ===
            Rectangle {
                id: debugPanel
                width: main.debugMode ? 350 : 0
                height: parent.height
                visible: main.debugMode && width > 0
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on width { NumberAnimation { duration: 200 } }
                border.color: "#9c27b0"
                border.width: 2
                radius: 5
                color: main.isDarkTheme ? "#2d2d2d" : "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "Панель отладки"
                        color: main.textColor
                        font.pixelSize: 20
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        Button {
                            id: backButton
                            text: "Назад"
                            enabled: main.debugMode && main.canStepBack
                            hoverEnabled: true
                            Shortcut {
                                sequence: "F7"
                                enabled: main.debugMode && main.canStepBack
                                onActivated: {
                                     if (main.debugMode && main.canStepBack) {
                                         console.log("Отладка: Шаг назад (F7)");
                                         myObrabotka.debugStepBack();
                                     }
                                }
                            }
                            Layout.preferredHeight: 45
                            Layout.preferredWidth: 120

                            background: Rectangle {
                                id: backButtonBg
                                color: {
                                    if (backButton.pressed) return Qt.darker("#616161", 1.2)
                                    else if (backButton.hovered) return Qt.lighter("#616161", 1.1)
                                    else return backButton.enabled ? "#616161" : main.buttonColor
                                }
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: backButton.enabled ? "white" : "#9e9e9e"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.bold: true
                            }

                            scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                            opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            onClicked: {
                                if (main.debugMode && main.canStepBack) {
                                    console.log("Отладка: Шаг назад (кнопка)");
                                    myObrabotka.debugStepBack();
                                }
                            }
                        }

                        Button {
                            id: forwardButton
                            text: "Вперёд"
                            enabled: main.debugMode && main.canStepForward
                            hoverEnabled: true
                            Shortcut {
                                sequence: "F8"
                                enabled: main.debugMode && main.canStepForward
                                onActivated: {
                                     if (main.debugMode && main.canStepForward) {
                                         console.log("Отладка: Шаг вперёд (F8)");
                                         myObrabotka.debugStep();
                                     }
                                }
                            }
                            Layout.preferredHeight: 45
                            Layout.preferredWidth: 120

                            background: Rectangle {
                                id: forwardButtonBg
                                color: {
                                    if (forwardButton.pressed) return Qt.darker("#616161", 1.2)
                                    else if (forwardButton.hovered) return Qt.lighter("#616161", 1.1)
                                    else return forwardButton.enabled ? "#616161" : main.buttonColor
                                }
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: forwardButton.enabled ? "white" : "#9e9e9e"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.bold: true
                            }

                            scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                            opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            onClicked: {
                                if (main.debugMode && main.canStepForward) {
                                    console.log("Отладка: Шаг вперёд (кнопка)");
                                    myObrabotka.debugStep();
                                }
                            }
                        }
                    }

                    Text {
                        text: "Таблица переменных:"
                        color: main.isDarkTheme ? "#bdbdbd" : "#616161"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.topMargin: 10
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ListView {
                            id: variablesListView
                            model: ListModel {
                                id: variablesModel
                            }
                            delegate: Rectangle {
                                width: parent ? parent.width : 0
                                height: 40
                                color: index % 2 === 0 ? (main.isDarkTheme ? "#3e3e3e" : "#f5f5f5") :
                                                      (main.isDarkTheme ? "#2e2e2e" : "#ffffff")
                                border.color: main.borderColor
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: model.name
                                        color: main.textColor
                                        width: (parent.width - parent.spacing) * 0.4
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                    Text {
                                        text: model.value
                                        color: main.isDarkTheme ? "#bdbdbd" : "#616161"
                                        width: (parent.width - parent.spacing) * 0.6
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                }
                            }
                            header: Rectangle {
                                width: parent ? parent.width : 0
                                height: 40
                                color: main.isDarkTheme ? "#424242" : "#e3f2fd"
                                border.color: main.isDarkTheme ? "#2d2d2d" : "#bbdefb"
                                border.width: 1

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: "Имя"
                                        color: main.textColor
                                        font.bold: true
                                        width: (parent.width - parent.spacing) * 0.4
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: "Значение"
                                        color: main.textColor
                                        font.bold: true
                                        width: (parent.width - parent.spacing) * 0.6
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        id: closeDebugButton
                        text: "Закрыть"
                        hoverEnabled: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 120

                        background: Rectangle {
                            id: closeDebugBg
                            color: {
                                if (closeDebugButton.pressed) return Qt.darker("#d32f2f", 1.2)
                                else if (closeDebugButton.hovered) return Qt.lighter("#d32f2f", 1.1)
                                else return "#f44336"
                            }
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                            font.bold: true
                        }

                        scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                        opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        onClicked: {
                            console.log("Отладка: Нажата кнопка 'Закрыть'");
                            myObrabotka.stopDebugging();
                        }
                    }
                }
            }
        }

        // === Область вывода (консоль) ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            border.color: main.borderColor
            border.width: 2
            radius: 5
            color: main.panelColor

            ScrollView {
                anchors.fill: parent
                anchors.margins: 5
                TextArea {
                    id: otvet
                    text: "Вывод"
                    readOnly: true
                    color: main.textColor
                    font.pixelSize: 18
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }

        // === Панель ввода ===
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: vvod
                placeholderText: "Ввод"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: main.textColor
                placeholderTextColor: main.isDarkTheme ? "#bdbdbd" : "#9e9e9e"
                font.pixelSize: 18
                hoverEnabled: true

                background: Rectangle {
                    id: vvodBg
                    anchors.fill: parent
                    border.color: vvod.hovered ? "#42a5f5" : main.borderColor
                    border.width: 2
                    radius: 8
                    color: main.isDarkTheme ? "#2d2d2d" : "#ffffff"

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }
                }

                Keys.onReturnPressed: myObrabotka.userInputReceived(vvod.text)
                Keys.onEnterPressed: myObrabotka.userInputReceived(vvod.text)
            }

            Button {
                id: sendButton
                text: "Отправить"
                hoverEnabled: true
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                onClicked: myObrabotka.userInputReceived(vvod.text)
                Shortcut { sequence: "Return"; onActivated: myObrabotka.userInputReceived(vvod.text) }
                Shortcut { sequence: "Enter"; onActivated: myObrabotka.userInputReceived(vvod.text) }

                background: Rectangle {
                    id: sendButtonBg
                    color: {
                        if (sendButton.pressed) return Qt.darker("#42a5f5", 1.2)
                        else if (sendButton.hovered) return Qt.lighter("#42a5f5", 1.1)
                        else return "#42a5f5"
                    }
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                    font.bold: true
                }

                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }
    }

    function createBlock(type) {
        if (!main.activeContainer) {
            console.warn("Нет активного контейнера!")
            return
        }
        var newBlock = spisok.createObject(main.activeContainer, {
            "blockType": type,
            "uniqueId": main.blockIdCounter
        })
        main.blockIdCounter++;
        console.log("Создан блок типа:", type, "с ID:", newBlock.uniqueId, "в контейнере:", main.activeContainer)
    }

    function insertBlockAfter(referenceBlock, type) {
        var parentContainer = referenceBlock.parent;
        if (!parentContainer) {
            console.warn("Не найден родительский контейнер для вставки");
            return;
        }
        var referenceIndex = -1;
        for (var i = 0; i < parentContainer.children.length; i++) {
            if (parentContainer.children[i] === referenceBlock) {
                referenceIndex = i;
                break;
            }
        }
        if (referenceIndex === -1) {
            console.error("Ссылочный блок не найден в родительском контейнере!");
            return;
        }

        var newBlock = spisok.createObject(parentContainer, { "blockType": type, "uniqueId": main.blockIdCounter++ });
        newBlock.z = referenceIndex + 2;
        for(i = referenceIndex + 1; i < parentContainer.children.length; ++i) {
             if(parentContainer.children[i] !== newBlock) {
                parentContainer.children[i].z = i + 1;
             }
        }
        newBlock.z = referenceIndex + 1;
    }

    function insertBlockBefore(referenceBlock, type) {
        var parentContainer = referenceBlock.parent;
        if (!parentContainer) {
            console.warn("Не найден родительский контейнер для вставки");
            return;
        }

        var referenceIndex = -1;
        for (var i = 0; i < parentContainer.children.length; i++) {
            if (parentContainer.children[i] === referenceBlock) {
                referenceIndex = i;
                break;
            }
        }
        if (referenceIndex === -1) {
            console.error("Ссылочный блок не найден в родительском контейнере!");
            return;
        }

        var newBlock = spisok.createObject(parentContainer, { "blockType": type, "uniqueId": main.blockIdCounter++ });
        newBlock.z = referenceIndex;
        for(i = referenceIndex; i < parentContainer.children.length; ++i) {
             if(parentContainer.children[i] !== newBlock) {
                parentContainer.children[i].z = i + 1;
             }
        }
    }

    Component {
        id: spisok
        Item {
            id: root
            width: Math.max(childrenRect.width, 350)
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: contentColumn.implicitHeight
            property string blockType: "действие"
            property bool isDebugHighlighted: false
            property int uniqueId: -1
            property bool isDebugStart: main.debugStartBlockId === root.uniqueId
            property bool hovered: false

            function highlightInSelfAndChildren(targetId) {
                if (root.uniqueId === targetId) {
                    root.isDebugHighlighted = true;
                } else {
                    root.isDebugHighlighted = false;
                }

                function highlightInContainer(cont) {
                    if (!cont) return;
                    for (var i = 0; i < cont.children.length; i++) {
                        var block = cont.children[i];
                        if (block && typeof block.highlightInSelfAndChildren === 'function') {
                            block.highlightInSelfAndChildren(targetId);
                        }
                    }
                }

                highlightInContainer(leftContainer);
                highlightInContainer(rightContainer);
                highlightInContainer(centerContainer);
                highlightInContainer(centerContainerCounter);
                highlightInContainer(centerContainerPost);
            }

            function getData() {
                function processContainer(cont) {
                    if (!cont || !cont.children) return []
                    var items = []
                    for (var i = 0; i < cont.children.length; i++) {
                        var child = cont.children[i]
                        if (child && typeof child.getData === "function") {
                            items.push(child.getData())
                        }
                    }
                    return items
                }

                var result;
                if (root.blockType === "усл") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputFieldDiamond.text.trim(),
                        "trueBranch": processContainer(leftContainer),
                        "falseBranch": processContainer(rightContainer)
                    };
                } else if (root.blockType === "счетчик") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": counterVarField.text.trim() + " = " +
                               counterFromField.text.trim() + " to " +
                               counterToField.text.trim() + " step " +
                               counterStepField.text.trim(),
                        "loopBody": processContainer(centerContainerCounter)
                    };
                } else if (root.blockType === "предусл") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputFieldDiamond.text.trim(),
                        "loopBody": processContainer(centerContainer)
                    };
                } else if (root.blockType === "постусл") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputFieldDiamond.text.trim(),
                        "loopBody": processContainer(centerContainerPost)
                    };
                } else {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputField.text.trim()
                    };
                }
                return result;
            }

            HoverHandler {
                id: blockHoverHandler
                enabled: !main.debugMode
                onHoveredChanged: {
                    root.hovered = hovered;
                    if (hovered) {
                        shapeItem.scale = 0.9;
                        shapeItem.opacity = 0.9;
                    } else {
                        shapeItem.scale = 1.0;
                        shapeItem.opacity = 1.0;
                    }
                }
            }

            Row {
                id: contentRow
                width: Math.max(parent.width, childrenRect.width)
                spacing: 5
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: setDebugStartButton
                    enabled: !main.debugMode && !["начало", "конец"].includes(root.blockType)
                    width: 30
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true

                    background: Rectangle {
                        id: debugStartBg
                        color: {
                            if (setDebugStartButton.pressed) return Qt.darker("#FF69B4", 1.2)
                            else if (setDebugStartButton.hovered) return Qt.lighter("#FF69B4", 1.1)
                            else return root.isDebugStart ? "#FF69B4" : main.buttonColor
                        }
                        radius: 15

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: "О"
                        color: root.isDebugStart ? "white" : main.textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: {
                        if (root.isDebugStart) {
                            main.debugStartBlockId = -1;
                        } else {
                            main.debugStartBlockId = root.uniqueId;
                        }
                        console.log("Установлен стартовый блок отладки: " + main.debugStartBlockId);
                    }
                }

                Column {
                    id: contentColumn
                    width: Math.max(350, childrenRect.width)
                    spacing: 10

                    // === ФИГУРА БЛОКА (ОСНОВНАЯ ЧАСТЬ) ===
                    Item {
                        id: shapeItem
                        width: Math.max(350, parent.width)
                        height: getDefaultHeight()
                        anchors.horizontalCenter: parent.horizontalCenter

                        function getDefaultHeight() {
                            switch (root.blockType) {
                                case "начало":
                                case "конец":
                                    return 80;
                                case "предусл":
                                case "постусл":
                                case "усл":
                                    return 120;
                                case "счетчик":
                                    return 120;
                                default:
                                    return 70;
                            }
                        }

                        Rectangle {
                            id: debugHighlight
                            anchors.fill: parent
                            border.color: "yellow"
                            border.width: 4
                            radius: 5
                            color: "transparent"
                            visible: root.isDebugHighlighted
                            z: 1
                        }

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            z: 0
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                const w = width, h = height, cx = w/2, cy = h/2, s = 20
                                ctx.beginPath()
                                var fillColor = root.blockType;
                                if (root.blockHoverHandler && root.blockHoverHandler.pressed) {
                                    fillColor = Qt.darker(getBlockColor(root.blockType), 1.2);
                                } else if (root.hovered) {
                                    fillColor = Qt.lighter(getBlockColor(root.blockType), 1.1);
                                } else {
                                    fillColor = getBlockColor(root.blockType);
                                }
                                ctx.fillStyle = fillColor;
                                ctx.strokeStyle = root.isDebugHighlighted ? "yellow" : (root.isDebugStart ? "#FF69B4" : (root.hovered ? Qt.darker("#e0e0e0", 1.2) : "#e0e0e0"))
                                ctx.lineWidth = root.isDebugHighlighted ? 3 : (root.isDebugStart ? 4 : 2)
                                if (["ввод", "вывод"].includes(root.blockType)) {
                                    ctx.moveTo(s, 0);
                                    ctx.lineTo(w, 0);
                                    ctx.lineTo(w-s, h);
                                    ctx.lineTo(0, h)
                                } else if (["усл", "предусл", "постусл"].includes(root.blockType)) {
                                    ctx.moveTo(cx, 5);
                                    ctx.lineTo(w-5, cy);
                                    ctx.lineTo(cx, h-5);
                                    ctx.lineTo(5, cy)
                                } else if (root.blockType === "счетчик") {
                                    const hex = 20
                                    ctx.moveTo(hex, 0);
                                    ctx.lineTo(w-hex, 0);
                                    ctx.lineTo(w, h/2)
                                    ctx.lineTo(w-hex, h);
                                    ctx.lineTo(hex, h);
                                    ctx.lineTo(0, h/2)
                                } else if (["начало", "конец"].includes(root.blockType)) {
                                    ctx.ellipse(5, 5, w-10, h-10)
                                } else {
                                    ctx.rect(0, 0, w, h)
                                }
                                ctx.closePath();
                                ctx.fill();
                                ctx.stroke()
                                if (["начало", "конец"].includes(root.blockType)) {
                                    ctx.fillStyle = main.textColor
                                    ctx.font = "bold 20px Arial"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText(root.blockType === "начало" ? "Начало" : "Конец", cx, cy)
                                }
                            }

                            function getBlockColor(type) {
                                var colors = {
                                    "ввод": "#ba68c8", "вывод": "#4db6ac", "действие": "#64b5f6", "усл": "#81c784",
                                    "счетчик": "#ef5350", "предусл": "#ffb74d", "постусл": "#ce93d8",
                                    "начало": "#64b5f6", "конец": "#ffb74d"
                                };
                                return colors[type] || "#64b5f6";
                            }
                        }

                        TextField {
                            id: inputField
                            enabled: !main.debugMode
                            anchors.centerIn: parent
                            width: parent.width - 30
                            visible: !["начало", "конец", "счетчик", "усл", "предусл", "постусл"].includes(root.blockType)
                            placeholderText: ({
                                "ввод": "Введите переменные для ввода...",
                                "вывод": "Введите данные для вывода...",
                                "действие": "Введите действие...",
                            })[root.blockType] || "Введите данные..."
                            color: main.textColor
                            placeholderTextColor: main.isDarkTheme ? "#757575" : "#9e9e9e"
                            selectByMouse: true
                            font.pixelSize: 26
                            font.bold: true
                            hoverEnabled: true

                            background: Rectangle {
                                color: "transparent";
                                border.width: 0
                            }
                        }

                        TextField {
                            id: inputFieldDiamond
                            enabled: !main.debugMode
                            visible: ["усл", "предусл", "постусл"].includes(root.blockType)
                            anchors.centerIn: parent
                            width: parent.width * 0.8
                            height: parent.height * 0.7
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            placeholderText: "Введите условие..."
                            color: main.textColor
                            placeholderTextColor: main.isDarkTheme ? "#757575" : "#9e9e9e"
                            selectByMouse: true
                            font.pixelSize: 26
                            font.bold: true
                            hoverEnabled: true

                            background: Rectangle {
                                color: "transparent";
                                border.width: 0
                            }
                        }

                        Column {
                            id: counterFieldsRow
                            anchors.centerIn: parent
                            spacing: 10
                            visible: root.blockType === "счетчик"

                            Row {
                                spacing: 20
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "Переменная:"
                                        color: main.textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterVarField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "i"
                                        color: main.textColor
                                        placeholderTextColor: main.isDarkTheme ? "#9e9e9e" : "#757575"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: main.borderColor
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "Шаг:"
                                        color: main.textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterStepField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "1"
                                        color: main.textColor
                                        placeholderTextColor: main.isDarkTheme ? "#9e9e9e" : "#757575"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: main.borderColor
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 20
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "От:"
                                        color: main.textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterFromField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "0"
                                        color: main.textColor
                                        placeholderTextColor: main.isDarkTheme ? "#9e9e9e" : "#757575"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: main.borderColor
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "До:"
                                        color: main.textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterToField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "10"
                                        color: main.textColor
                                        placeholderTextColor: main.isDarkTheme ? "#9e9e9e" : "#757575"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: main.borderColor
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.left: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 5
                            spacing: 2

                            Button {
                                id: addAboveButton
                                enabled: !main.debugMode
                                width: 30
                                height: 30
                                hoverEnabled: true

                                background: Rectangle {
                                    id: addAboveBg
                                    color: {
                                        if (addAboveButton.pressed) return Qt.darker(main.pressedColor, 1.2)
                                        else if (addAboveButton.hovered) return Qt.lighter(main.hoverColor, 1.1)
                                        else return main.buttonColor
                                    }
                                    radius: 3

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.fillStyle = main.textColor;
                                            var w = width;
                                            var h = height;
                                            var stemWidth = w * 0.2;
                                            var headHeight = h * 0.3;
                                            var headWidth = w * 0.4;
                                            ctx.fillRect(w/2 - stemWidth/2, headHeight, stemWidth, h - headHeight);
                                            ctx.beginPath();
                                            ctx.moveTo(w/2 - headWidth/2, headHeight);
                                            ctx.lineTo(w/2 + headWidth/2, headHeight);
                                            ctx.lineTo(w/2, 0);
                                            ctx.closePath();
                                            ctx.fill();
                                        }
                                    }
                                }

                                contentItem: Item {}

                                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                onClicked: {
                                    console.log("Кнопка 'Добавить выше' нажата для блока типа:", root.blockType);
                                    main.insertBlockBefore(root, main.selectedBlockType);
                                }
                            }

                            Button {
                                id: addBelowButton
                                enabled: !main.debugMode
                                width: 30
                                height: 30
                                hoverEnabled: true

                                background: Rectangle {
                                    id: addBelowBg
                                    color: {
                                        if (addBelowButton.pressed) return Qt.darker(main.pressedColor, 1.2)
                                        else if (addBelowButton.hovered) return Qt.lighter(main.hoverColor, 1.1)
                                        else return main.buttonColor
                                    }
                                    radius: 3

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.fillStyle = main.textColor;
                                            var w = width;
                                            var h = height;
                                            var stemWidth = w * 0.2;
                                            var headHeight = h * 0.3;
                                            var headWidth = w * 0.4;
                                            ctx.fillRect(w/2 - stemWidth/2, 0, stemWidth, h - headHeight);
                                            ctx.beginPath();
                                            ctx.moveTo(w/2 - headWidth/2, h - headHeight);
                                            ctx.lineTo(w/2 + headWidth/2, h - headHeight);
                                            ctx.lineTo(w/2, h);
                                            ctx.closePath();
                                            ctx.fill();
                                        }
                                    }
                                }

                                contentItem: Item {}

                                scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                onClicked: {
                                    console.log("Кнопка 'Добавить ниже' нажата для блока типа:", root.blockType);
                                    main.insertBlockAfter(root, main.selectedBlockType);
                                }
                            }
                        }

                        TapHandler {
                            enabled: !main.debugMode
                            acceptedButtons: Qt.RightButton
                            onTapped: {
                                console.log("Блок удалён правым кликом. ID:", root.uniqueId);
                                root.destroy()
                            }
                        }

                        TapHandler {
                            enabled: !main.debugMode
                            acceptedButtons: Qt.LeftButton
                            onDoubleTapped: {
                                console.log("Блок удалён двойным кликом. ID:", root.uniqueId);
                                root.destroy()
                            }
                        }
                    }

                    // === ОБЛАСТЬ ДЛЯ СЧЕТЧИКА (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: counterContainer
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? counterContent.height + 10 : 0
                        visible: root.blockType === "счетчик"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: counterContent
                            width: Math.max(400, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                id: counterRect
                                width: Math.max(400, centerContainerCounter.childrenRect.width + 40)
                                height: Math.max(160, centerContainerCounter.childrenRect.height + 50)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerCounter ? "#9c27b0" : main.borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 300 }
                                }

                                Column {
                                    id: centerContainerCounter
                                    width: Math.max(350, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10
                                }

                                Button {
                                    id: counterActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 35
                                    height: 35
                                    text: "A"
                                    hoverEnabled: true

                                    background: Rectangle {
                                        id: counterActivateBg
                                        color: {
                                            if (counterActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                            else if (counterActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                            else return main.activeContainer === centerContainerCounter ? "#9c27b0" : main.buttonColor
                                        }
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

                                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    onClicked: {
                                        if (main.activeContainer === centerContainerCounter) {
                                            main.activeContainer = null
                                            console.log("Область тела счетчика деактивирована")
                                        } else {
                                            main.activeContainer = centerContainerCounter
                                            console.log("Область тела счетчика активирована")
                                        }
                                    }
                                }

                                TapHandler {
                                    enabled: !main.debugMode
                                    onTapped: {
                                        if (main.activeContainer === centerContainerCounter) {
                                            createBlock(main.selectedBlockType)
                                            console.log("Создан блок типа:", main.selectedBlockType, "в теле счетчика")
                                        }
                                        main.activeContainer = centerContainerCounter
                                    }
                                }
                            }
                        }
                    }

                    // === ОБЛАСТЬ ДЛЯ ПРЕДУСЛОВИЯ (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: cycleWrapper
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? cycleContentDefault.height + 10 : 0
                        visible: root.blockType === "предусл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: cycleContentDefault
                            width: Math.max(400, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                id: cycleRect
                                width: Math.max(400, centerContainer.childrenRect.width + 40)
                                height: Math.max(160, centerContainer.childrenRect.height + 50)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainer ? "#9c27b0" : main.borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 300 }
                                }

                                Column {
                                    id: centerContainer
                                    width: Math.max(350, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10
                                }

                                Button {
                                    id: cycleActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 35
                                    height: 35
                                    text: "A"
                                    hoverEnabled: true

                                    background: Rectangle {
                                        id: cycleActivateBg
                                        color: {
                                            if (cycleActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                            else if (cycleActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                            else return main.activeContainer === centerContainer ? "#9c27b0" : main.buttonColor
                                        }
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

                                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    onClicked: {
                                        if (main.activeContainer === centerContainer) {
                                            main.activeContainer = null
                                            console.log("Область цикла деактивирована")
                                        } else {
                                            main.activeContainer = centerContainer
                                            console.log("Область цикла активирована")
                                        }
                                    }
                                }

                                TapHandler {
                                    enabled: !main.debugMode
                                    onTapped: {
                                        if (main.activeContainer === centerContainer) {
                                            createBlock(main.selectedBlockType)
                                            console.log("Создан блок типа:", main.selectedBlockType, "в цикле")
                                        }
                                        main.activeContainer = centerContainer
                                    }
                                }
                            }
                        }
                    }

                    // === ОБЛАСТЬ ДЛЯ УСЛОВИЯ (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: conditionWrapper
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? conditionContent.height + 10 : 0
                        visible: root.blockType === "усл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: conditionContent
                            width: Math.max(600, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Row {
                                width: Math.max(600, childrenRect.width)
                                spacing: 20
                                anchors.horizontalCenter: parent.horizontalCenter

                                // Левая ветка (истина)
                                Rectangle {
                                    id: leftRect
                                    width: Math.max(280, leftContainer.childrenRect.width + 40)
                                    height: Math.max(160, leftContainer.childrenRect.height + 50)
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === leftContainer ? "#9c27b0" : main.borderColor)
                                    border.width: root.isDebugHighlighted ? 4 : 2
                                    radius: 5
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 300 }
                                    }

                                    Column {
                                        id: leftContainer
                                        width: Math.max(250, childrenRect.width)
                                        anchors.centerIn: parent
                                        spacing: 10
                                    }

                                    Button {
                                        id: leftActivateBtn
                                        enabled: !main.debugMode
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 5
                                        width: 35
                                        height: 35
                                        text: "A"
                                        hoverEnabled: true

                                        background: Rectangle {
                                            id: leftActivateBg
                                            color: {
                                                if (leftActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                                else if (leftActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                                else return main.activeContainer === leftContainer ? "#9c27b0" : main.buttonColor
                                            }
                                            radius: width / 2

                                            Behavior on color {
                                                ColorAnimation { duration: 150 }
                                            }
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            color: "white"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 18
                                            font.bold: true
                                        }

                                        scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                        opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                        Behavior on opacity { NumberAnimation { duration: 100 } }

                                        onClicked: {
                                            if (main.activeContainer === leftContainer) {
                                                main.activeContainer = null
                                                console.log("Левая ветка условия деактивирована")
                                            } else {
                                                main.activeContainer = leftContainer
                                                console.log("Левая ветка условия активирована")
                                            }
                                        }
                                    }

                                    TapHandler {
                                        enabled: !main.debugMode
                                        onTapped: {
                                            if (main.activeContainer === leftContainer) {
                                                createBlock(main.selectedBlockType)
                                                console.log("Создан блок типа:", main.selectedBlockType, "в левой ветке условия")
                                            }
                                            main.activeContainer = leftContainer
                                        }
                                    }
                                }

                                // Правая ветка (ложь)
                                Rectangle {
                                    id: rightRect
                                    width: Math.max(280, rightContainer.childrenRect.width + 40)
                                    height: Math.max(160, rightContainer.childrenRect.height + 50)
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === rightContainer ? "#9c27b0" : main.borderColor)
                                    border.width: root.isDebugHighlighted ? 4 : 2
                                    radius: 5
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 300 }
                                    }

                                    Column {
                                        id: rightContainer
                                        width: Math.max(250, childrenRect.width)
                                        anchors.centerIn: parent
                                        spacing: 10
                                    }

                                    Button {
                                        id: rightActivateBtn
                                        enabled: !main.debugMode
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 5
                                        width: 35
                                        height: 35
                                        text: "A"
                                        hoverEnabled: true

                                        background: Rectangle {
                                            id: rightActivateBg
                                            color: {
                                                if (rightActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                                else if (rightActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                                else return main.activeContainer === rightContainer ? "#9c27b0" : main.buttonColor
                                            }
                                            radius: width / 2

                                            Behavior on color {
                                                ColorAnimation { duration: 150 }
                                            }
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            color: "white"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 18
                                            font.bold: true
                                        }

                                        scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                        opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                        Behavior on opacity { NumberAnimation { duration: 100 } }

                                        onClicked: {
                                            if (main.activeContainer === rightContainer) {
                                                main.activeContainer = null
                                                console.log("Правая ветка условия деактивирована")
                                            } else {
                                                main.activeContainer = rightContainer
                                                console.log("Правая ветка условия активирована")
                                            }
                                        }
                                    }

                                    TapHandler {
                                        enabled: !main.debugMode
                                        onTapped: {
                                            if (main.activeContainer === rightContainer) {
                                                createBlock(main.selectedBlockType)
                                                console.log("Создан блок типа:", main.selectedBlockType, "в правой ветке условия")
                                            }
                                            main.activeContainer = rightContainer
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // === ОБЛАСТЬ ДЛЯ ПОСТУСЛОВИЯ (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: postConditionWrapper
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? postConditionContent.height + 10 : 0
                        visible: root.blockType === "постусл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: postConditionContent
                            width: Math.max(400, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                id: postRect
                                width: Math.max(400, centerContainerPost.childrenRect.width + 40)
                                height: Math.max(160, centerContainerPost.childrenRect.height + 50)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerPost ? "#9c27b0" : main.borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 300 }
                                }

                                Column {
                                    id: centerContainerPost
                                    width: Math.max(350, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10
                                }

                                Button {
                                    id: postActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 35
                                    height: 35
                                    text: "A"
                                    hoverEnabled: true

                                    background: Rectangle {
                                        id: postActivateBg
                                        color: {
                                            if (postActivateBtn.pressed) return Qt.darker("#9c27b0", 1.2)
                                            else if (postActivateBtn.hovered) return Qt.lighter("#9c27b0", 1.1)
                                            else return main.activeContainer === centerContainerPost ? "#9c27b0" : main.buttonColor
                                        }
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

                                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    onClicked: {
                                        if (main.activeContainer === centerContainerPost) {
                                            main.activeContainer = null
                                            console.log("Область постусловия деактивирована")
                                        } else {
                                            main.activeContainer = centerContainerPost
                                            console.log("Область постусловия активирована")
                                        }
                                    }
                                }

                                TapHandler {
                                    enabled: !main.debugMode
                                    onTapped: {
                                        if (main.activeContainer === centerContainerPost) {
                                            createBlock(main.selectedBlockType)
                                            console.log("Создан блок типа:", main.selectedBlockType, "в постусловии")
                                        }
                                        main.activeContainer = centerContainerPost
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function collectData(a) {
        function processContainer(cont) {
            if (!cont || !cont.children) return []
            var items = []
            for (var i = 0; i < cont.children.length; i++) {
                var child = cont.children[i]
                if (child && typeof child.getData === "function") {
                    items.push(child.getData())
                }
            }
            return items
        }
        var data = processContainer(container)

        console.log("📤 Отправка структуры алгоритма в C++:")
        console.log(JSON.stringify(data, null, 2))

        if(a === 1){
            myObrabotka.myPriem(data)
        } else if(a === 2){
            myObrabotka.startDebugging(data, main.debugStartBlockId)
        }
        return data
    }


    function updateBlockHighlight() {
        // Вызываем рекурсивную подсветку для всех блоков верхнего уровня
        for (var i = 0; i < container.children.length; i++) {
            var block = container.children[i];
            if (block && typeof block.highlightInSelfAndChildren === 'function') {
                block.highlightInSelfAndChildren(main.currentDebugBlockId);
            }
        }
    }

    onCurrentDebugBlockIdChanged: updateBlockHighlight()

    function loadAlgorithm(algorithmData, parentContainer) {
        parentContainer.destroyChildren() // Очищаем контейнер

        function createBlocksRecursive(dataArray, container) {
            for (var i = 0; i < dataArray.length; i++) {
                var blockData = dataArray[i];
                var newBlock = spisok.createObject(container, {
                    "blockType": blockData.type,
                    "uniqueId": blockData.uniqueId
                });

                // Присваиваем максимальный ID, чтобы новые блоки не конфликтовали
                if (blockData.uniqueId >= main.blockIdCounter) {
                    main.blockIdCounter = blockData.uniqueId + 1;
                }

                if (blockData.type === "усл") {
                    newBlock.contentItem.findChild("inputFieldDiamond").text = blockData.input;
                    createBlocksRecursive(blockData.trueBranch, newBlock.contentItem.findChild("leftContainer"));
                    createBlocksRecursive(blockData.falseBranch, newBlock.contentItem.findChild("rightContainer"));
                } else if (blockData.type === "счетчик") {
                    var counterParts = blockData.input.match(/(\w+)\s*=\s*(.+)\s*to\s*(.+)\s*step\s*(.+)/);
                    if(counterParts) {
                        newBlock.contentItem.findChild("counterVarField").text = counterParts[1].trim();
                        newBlock.contentItem.findChild("counterFromField").text = counterParts[2].trim();
                        newBlock.contentItem.findChild("counterToField").text = counterParts[3].trim();
                        newBlock.contentItem.findChild("counterStepField").text = counterParts[4].trim();
                    }
                    createBlocksRecursive(blockData.loopBody, newBlock.contentItem.findChild("centerContainerCounter"));
                } else if (blockData.type === "предусл" || blockData.type === "постусл") {
                    newBlock.contentItem.findChild("inputFieldDiamond").text = blockData.input;
                    var loopContainer = newBlock.contentItem.findChild("centerContainer") || newBlock.contentItem.findChild("centerContainerPost");
                    createBlocksRecursive(blockData.loopBody, loopContainer);
                } else if (blockData.type !== "начало" && blockData.type !== "конец") {
                    newBlock.contentItem.findChild("inputField").text = blockData.input;
                }
            }
        }
        createBlocksRecursive(algorithmData, parentContainer);
    }


    FileDialog {
        id: saveFileDialog
        title: "Сохранить алгоритм"
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            var path = saveFileDialog.file.toString().substring(Qt.platform.os === "windows" ? 8 : 7)
            var data = collectData(0)
            myObrabotka.saveAlgorithmToFile(data, path)
            information_save.text = "Алгоритм успешно сохранен"
            information_save.open()
        }
    }

    FileDialog {
        id: openFileDialog
        title: "Открыть алгоритм"
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            var path = openFileDialog.file.toString().substring(Qt.platform.os === "windows" ? 8 : 7)
            myObrabotka.loadAlgorithmFromFile(path)
        }
    }

    Popup {
        id: newAlgorithmDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        height: 150
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 10
        background: Rectangle {
            color: main.panelColor
            border.color: main.borderColor
            border.width: 2
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            Text {
                text: "Вы уверены, что хотите создать новый алгоритм? Все несохраненные данные будут утеряны."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: main.textColor
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    id: okButton
                    text: "Ok"
                    hoverEnabled: true

                    background: Rectangle {
                        id: okButtonBg
                        color: {
                            if (okButton.pressed) return Qt.darker("#4caf50", 1.2)
                            else if (okButton.hovered) return Qt.lighter("#4caf50", 1.1)
                            else return "#4caf50"
                        }
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: {
                        container.destroyChildren()
                        main.blockIdCounter = 0
                        main.debugStartBlockId = -1
                        console.log("Создан новый пустой алгоритм")
                        newAlgorithmDialog.close()
                    }
                }

                Button {
                    id: cancelButton
                    text: "Cancel"
                    hoverEnabled: true

                    background: Rectangle {
                        id: cancelButtonBg
                        color: {
                            if (cancelButton.pressed) return Qt.darker("#f44336", 1.2)
                            else if (cancelButton.hovered) return Qt.lighter("#f44336", 1.1)
                            else return "#f44336"
                        }
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: newAlgorithmDialog.close()
                }
            }
        }
    }

    Popup {
        id: errorDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 300
        height: 150
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 10
        property alias text: errorText.text

        background: Rectangle {
            color: main.panelColor
            border.color: "#f44336"
            border.width: 2
            radius: 8
        }

        ColumnLayout{
            anchors.fill: parent
             Text {
                id: errorText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: main.textColor
            }
            RowLayout{
                 Layout.alignment: Qt.AlignHCenter
                 Button {
                    id: errorOkButton
                    text: "Ok"
                    hoverEnabled: true

                    background: Rectangle {
                        id: errorOkButtonBg
                        color: {
                            if (errorOkButton.pressed) return Qt.darker("#f44336", 1.2)
                            else if (errorOkButton.hovered) return Qt.lighter("#f44336", 1.1)
                            else return "#f44336"
                        }
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: errorDialog.close()
                }
            }
        }
    }

    Popup {
        id: helpDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 600
        height: 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 10

        background: Rectangle {
            color: main.panelColor
            border.color: "#42a5f5"
            border.width: 2
            radius: 8
        }

        ColumnLayout{
            anchors.fill: parent
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                TextArea {
                    readOnly: true
                    wrapMode: Text.WordWrap
                    text: "Добро пожаловать в редактор алгоритмов!\n\n"
                        + "Горячие клавиши:\n"
                        + "F1: Запуск\n"
                        + "F2: Сохранить\n"
                        + "F3: Открыть\n"
                        + "F4: Новый алгоритм\n"
                        + "F5: Справка\n"
                        + "F6: Отладка/Закончить отладку\n"
                        + "F7: Ввод / Шаг назад (в режиме отладки)\n"
                        + "F8: Вывод / Шаг вперёд (в режиме отладки)\n"
                        + "F9: Действие\n"
                        + "F10: Счетчик\n"
                        + "F11: Предусловие\n"
                        + "F12: Постусловие\n\n"
                        + "Для создания блока выберите его тип в выпадающем списке и кликните в нужной области (основной или внутри другого блока).\n"
                        + "Для удаления блока кликните по нему правой кнопкой мыши или дважды левой.\n"
                        + "Для активации области для добавления блоков (например, ветки 'Да'/'Нет' в условии) кликните по кнопке 'A' в углу этой области."
                    color: main.textColor
                }
            }
            RowLayout{
                Layout.alignment: Qt.AlignHCenter
                Button {
                    id: helpOkButton
                    text: "Ok"
                    hoverEnabled: true

                    background: Rectangle {
                        id: helpOkButtonBg
                        color: {
                            if (helpOkButton.pressed) return Qt.darker("#42a5f5", 1.2)
                            else if (helpOkButton.hovered) return Qt.lighter("#42a5f5", 1.1)
                            else return "#42a5f5"
                        }
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: helpDialog.close()
                }
            }
        }
    }

    Popup {
        id: information_save
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 250
        height: 100
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 10
        property alias text: infoText.text

        background: Rectangle {
            color: main.panelColor
            border.color: "#4caf50"
            border.width: 2
            radius: 8
        }

         ColumnLayout{
            anchors.fill: parent
            Text {
                id: infoText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: main.textColor
                font.bold: true
            }
            RowLayout{
                Layout.alignment: Qt.AlignHCenter
                Button {
                    id: infoOkButton
                    text: "Ok"
                    hoverEnabled: true

                    background: Rectangle {
                        id: infoOkButtonBg
                        color: {
                            if (infoOkButton.pressed) return Qt.darker("#4caf50", 1.2)
                            else if (infoOkButton.hovered) return Qt.lighter("#4caf50", 1.1)
                            else return "#4caf50"
                        }
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    scale: pressed ? 1.1 : (hovered ? 0.9 : 1.0)
                    opacity: pressed ? 0.7 : (hovered ? 0.9 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    onClicked: information_save.close()
                }
            }
        }
    }

    Component {
        id: miniBlockShapeItem
        Canvas {
            property string blockType: "действие"
            antialiasing: true
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height, cx = w/2, cy = h/2, s = 5
                ctx.beginPath()
                ctx.fillStyle = getBlockColor(blockType)
                ctx.strokeStyle = main.borderColor
                ctx.lineWidth = 1
                if (["ввод", "вывод"].includes(blockType)) {
                    ctx.moveTo(s, 0); ctx.lineTo(w, 0); ctx.lineTo(w-s, h); ctx.lineTo(0, h)
                } else if (["усл", "предусл", "постусл"].includes(blockType)) {
                    ctx.moveTo(cx, 0); ctx.lineTo(w, cy); ctx.lineTo(cx, h); ctx.lineTo(0, cy)
                } else if (blockType === "счетчик") {
                    const hex = 5; ctx.moveTo(hex, 0); ctx.lineTo(w-hex, 0); ctx.lineTo(w, h/2); ctx.lineTo(w-hex, h); ctx.lineTo(hex, h); ctx.lineTo(0, h/2)
                } else if (["начало", "конец"].includes(blockType)) {
                    ctx.ellipse(1, 1, w-2, h-2)
                } else {
                    ctx.rect(0, 0, w, h)
                }
                ctx.closePath();
                ctx.fill();
                ctx.stroke()
            }
            function getBlockColor(type) {
                var colors = {
                    "ввод": "#ba68c8", "вывод": "#4db6ac", "действие": "#64b5f6", "усл": "#81c784",
                    "счетчик": "#ef5350", "предусл": "#ffb74d", "постусл": "#ce93d8",
                    "начало": "#64b5f6", "конец": "#ffb74d"
                };
                return colors[type] || "#64b5f6";
            }
        }
    }
}
