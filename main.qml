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

    // Стандартные темные цвета (для сброса)
    property color defaultBackgroundColor: "#121212"
    property color defaultPanelColor: "#1e1e1e"
    property color defaultTextColor: "#e0e0e0"
    property color defaultBorderColor: "#424242"
    property color defaultButtonColor: "#424242"
    property color defaultHoverColor: "#616161"
    property color defaultPressedColor: "#757575"

    // Цвета кнопок спавна блоков
    property color defaultInputColor: "#ba68c8"
    property color defaultOutputColor: "#4db6ac"
    property color defaultActionColor: "#64b5f6"
    property color defaultCounterColor: "#ef5350"
    property color defaultPrecondColor: "#ffb74d"
    property color defaultPostcondColor: "#ce93d8"
    property color defaultCondColor: "#81c784"
    property color defaultStartColor: "#64b5f6"
    property color defaultEndColor: "#ffb74d"

    // Текущие цвета (могут меняться пользователем)
    property color backgroundColor: defaultBackgroundColor
    property color panelColor: defaultPanelColor
    property color textColor: defaultTextColor
    property color borderColor: defaultBorderColor
    property color buttonColor: defaultButtonColor
    property color hoverColor: defaultHoverColor
    property color pressedColor: defaultPressedColor

    property color inputColor: defaultInputColor
    property color outputColor: defaultOutputColor
    property color actionColor: defaultActionColor
    property color counterColor: defaultCounterColor
    property color precondColor: defaultPrecondColor
    property color postcondColor: defaultPostcondColor
    property color condColor: defaultCondColor
    property color startColor: defaultStartColor
    property color endColor: defaultEndColor

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

    // Функция сброса всех цветов к стандартным
    function resetAllColors() {
        backgroundColor = defaultBackgroundColor
        panelColor = defaultPanelColor
        textColor = defaultTextColor
        borderColor = defaultBorderColor
        buttonColor = defaultButtonColor
        hoverColor = defaultHoverColor
        pressedColor = defaultPressedColor
        inputColor = defaultInputColor
        outputColor = defaultOutputColor
        actionColor = defaultActionColor
        counterColor = defaultCounterColor
        precondColor = defaultPrecondColor
        postcondColor = defaultPostcondColor
        condColor = defaultCondColor
        startColor = defaultStartColor
        endColor = defaultEndColor
    }

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
            }
        }

        onErrorOccurred: (errorMessage) => {
            console.log("Ошибка при загрузке:", errorMessage)
        }
    }

    property string userInputResult: ""

    // Диалог выбора цвета
    ColorDialog {
        id: colorPicker
        title: "Выберите цвет"
        visible: false
        modality: Qt.ApplicationModal

        onAccepted: {
            if (colorPicker.currentTarget === "border") main.borderColor = colorPicker.color
            else if (colorPicker.currentTarget === "button") main.buttonColor = colorPicker.color
            else if (colorPicker.currentTarget === "background") main.backgroundColor = colorPicker.color
            else if (colorPicker.currentTarget === "panel") main.panelColor = colorPicker.color
            else if (colorPicker.currentTarget === "input") main.inputColor = colorPicker.color
            else if (colorPicker.currentTarget === "output") main.outputColor = colorPicker.color
            else if (colorPicker.currentTarget === "action") main.actionColor = colorPicker.color
            else if (colorPicker.currentTarget === "counter") main.counterColor = colorPicker.color
            else if (colorPicker.currentTarget === "precond") main.precondColor = colorPicker.color
            else if (colorPicker.currentTarget === "postcond") main.postcondColor = colorPicker.color
            else if (colorPicker.currentTarget === "cond") main.condColor = colorPicker.color
            else if (colorPicker.currentTarget === "start") main.startColor = colorPicker.color
            else if (colorPicker.currentTarget === "end") main.endColor = colorPicker.color
            else if (colorPicker.currentTarget === "text") main.textColor = colorPicker.color
        }

        property string currentTarget: ""
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // === Единая панель кнопок (запуск, отладка, настройки и спавн блоков) ===
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 5

            // Кнопка запуска
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
                        if (runButton.pressed) {
                            var c = Qt.darker(buttonColor, 1.25);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else if (runButton.hovered) {
                            var c = Qt.lighter(buttonColor, 1.15);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else return buttonColor
                    }
                    border.color: borderColor
                    border.width: 1
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            // Кнопка отладки
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
                        if (debugButton.pressed) {
                            var c = Qt.darker(buttonColor, 1.25);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else if (debugButton.hovered) {
                            var c = Qt.lighter(buttonColor, 1.15);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else return buttonColor
                    }
                    border.color: borderColor
                    border.width: 1
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

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

            // Кнопка настроек
            Button {
                id: settingsButton
                text: "Настройки"
                hoverEnabled: true
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150

                background: Rectangle {
                    id: settingsBg
                    color: {
                        if (settingsButton.pressed) {
                            var c = Qt.darker(buttonColor, 1.25);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else if (settingsButton.hovered) {
                            var c = Qt.lighter(buttonColor, 1.15);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else return buttonColor
                    }
                    border.color: borderColor
                    border.width: 1
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    font.bold: true
                }

                onClicked: {
                    settingsWindow.show()
                }
            }

            // Разделитель
            Rectangle {
                Layout.preferredHeight: 40
                Layout.preferredWidth: 2
                color: borderColor

                Behavior on color {
                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }

            // Выбор типа блока
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
                    color: buttonColor
                    border.color: blockTypeSelector.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                    border.width: 2
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                        color: textColor
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
                        color: delegateItem.highlighted ? hoverColor :
                                (delegateItem.hovered ? Qt.lighter(panelColor, 1.15) : panelColor)
                        border.color: borderColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                            color: textColor
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
                        ctx.fillStyle = textColor
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width / 2, height)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }

            // Кнопки с фигурами блоков (без внешних бордеров)
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: inputCanvas
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
                            var fillColor = inputBtn.pressed ? Qt.darker(inputColor, 1.3) :
                                            (inputBtn.hovered ? Qt.lighter(inputColor, 1.2) : inputColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = inputBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Ввод"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: inputCanvas.requestPaint()
                onHoveredChanged: inputCanvas.requestPaint()
                Connections {
                    target: main
                    function onInputColorChanged() { inputCanvas.requestPaint() }
                    function onBorderColorChanged() { inputCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: outputCanvas
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
                            var fillColor = outputBtn.pressed ? Qt.darker(outputColor, 1.3) :
                                            (outputBtn.hovered ? Qt.lighter(outputColor, 1.2) : outputColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = outputBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Вывод"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: outputCanvas.requestPaint()
                onHoveredChanged: outputCanvas.requestPaint()
                Connections {
                    target: main
                    function onOutputColorChanged() { outputCanvas.requestPaint() }
                    function onBorderColorChanged() { outputCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: actionCanvas
                        anchors.fill: parent
                        anchors.margins: 3
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var fillColor = actionBtn.pressed ? Qt.darker(actionColor, 1.3) :
                                            (actionBtn.hovered ? Qt.lighter(actionColor, 1.2) : actionColor)
                            ctx.fillStyle = fillColor
                            ctx.fillRect(0, 0, w, h)
                            ctx.strokeStyle = actionBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.strokeRect(0, 0, w, h)
                        }
                    }

                    Text {
                        text: "Действие"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: actionCanvas.requestPaint()
                onHoveredChanged: actionCanvas.requestPaint()
                Connections {
                    target: main
                    function onActionColorChanged() { actionCanvas.requestPaint() }
                    function onBorderColorChanged() { actionCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: counterCanvas
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
                            var fillColor = counterBtn.pressed ? Qt.darker(counterColor, 1.3) :
                                            (counterBtn.hovered ? Qt.lighter(counterColor, 1.2) : counterColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = counterBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Счетчик"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: counterCanvas.requestPaint()
                onHoveredChanged: counterCanvas.requestPaint()
                Connections {
                    target: main
                    function onCounterColorChanged() { counterCanvas.requestPaint() }
                    function onBorderColorChanged() { counterCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: precondCanvas
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
                            var fillColor = precondBtn.pressed ? Qt.darker(precondColor, 1.3) :
                                            (precondBtn.hovered ? Qt.lighter(precondColor, 1.2) : precondColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = precondBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Предусл"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: precondCanvas.requestPaint()
                onHoveredChanged: precondCanvas.requestPaint()
                Connections {
                    target: main
                    function onPrecondColorChanged() { precondCanvas.requestPaint() }
                    function onBorderColorChanged() { precondCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: postcondCanvas
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
                            var fillColor = postcondBtn.pressed ? Qt.darker(postcondColor, 1.3) :
                                            (postcondBtn.hovered ? Qt.lighter(postcondColor, 1.2) : postcondColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = postcondBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Постусл"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: postcondCanvas.requestPaint()
                onHoveredChanged: postcondCanvas.requestPaint()
                Connections {
                    target: main
                    function onPostcondColorChanged() { postcondCanvas.requestPaint() }
                    function onBorderColorChanged() { postcondCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: condCanvas
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
                            var fillColor = condBtn.pressed ? Qt.darker(condColor, 1.3) :
                                            (condBtn.hovered ? Qt.lighter(condColor, 1.2) : condColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = condBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }

                    Text {
                        text: "Усл"
                        anchors.centerIn: parent
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onPressedChanged: condCanvas.requestPaint()
                onHoveredChanged: condCanvas.requestPaint()
                Connections {
                    target: main
                    function onCondColorChanged() { condCanvas.requestPaint() }
                    function onBorderColorChanged() { condCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: startCanvas
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
                            var fillColor = startBtn.pressed ? Qt.darker(startColor, 1.3) :
                                            (startBtn.hovered ? Qt.lighter(startColor, 1.2) : startColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = startBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.stroke()
                            ctx.fillStyle = textColor
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Начало", cx, cy)
                        }
                    }
                }

                onPressedChanged: startCanvas.requestPaint()
                onHoveredChanged: startCanvas.requestPaint()
                Connections {
                    target: main
                    function onStartColorChanged() { startCanvas.requestPaint() }
                    function onBorderColorChanged() { startCanvas.requestPaint() }
                }
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
                    border.width: 0  // Убираем внешний бордер
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    Canvas {
                        id: endCanvas
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
                            var fillColor = endBtn.pressed ? Qt.darker(endColor, 1.3) :
                                            (endBtn.hovered ? Qt.lighter(endColor, 1.2) : endColor)
                            ctx.fillStyle = fillColor
                            ctx.fill()
                            ctx.strokeStyle = endBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                            ctx.stroke()
                            ctx.fillStyle = textColor
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Конец", cx, cy)
                        }
                    }
                }

                onPressedChanged: endCanvas.requestPaint()
                onHoveredChanged: endCanvas.requestPaint()
                Connections {
                    target: main
                    function onEndColorChanged() { endCanvas.requestPaint() }
                    function onBorderColorChanged() { endCanvas.requestPaint() }
                }
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
                border.color: main.activeContainer === container ? "#9c27b0" : borderColor
                border.width: 2
                radius: 5
                color: panelColor

                Behavior on border.color {
                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                if (mainActivateBtn.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (mainActivateBtn.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return main.activeContainer === container ? "#9c27b0" : buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: width / 2

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                            font.bold: true
                        }

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
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                border.color: "#9c27b0"
                border.width: 2
                radius: 5
                color: "#2d2d2d"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "Панель отладки"
                        color: textColor
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
                                    if (backButton.pressed) {
                                        var c = Qt.darker(buttonColor, 1.25);
                                        return Qt.rgba(c.r, c.g, c.b, 1);
                                    } else if (backButton.hovered) {
                                        var c = Qt.lighter(buttonColor, 1.15);
                                        return Qt.rgba(c.r, c.g, c.b, 1);
                                    } else return backButton.enabled ? "#616161" : buttonColor
                                }
                                border.color: borderColor
                                border.width: 1
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: backButton.enabled ? textColor : "#9e9e9e"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.bold: true
                            }

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
                                    if (forwardButton.pressed) {
                                        var c = Qt.darker(buttonColor, 1.25);
                                        return Qt.rgba(c.r, c.g, c.b, 1);
                                    } else if (forwardButton.hovered) {
                                        var c = Qt.lighter(buttonColor, 1.15);
                                        return Qt.rgba(c.r, c.g, c.b, 1);
                                    } else return forwardButton.enabled ? "#616161" : buttonColor
                                }
                                border.color: borderColor
                                border.width: 1
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: forwardButton.enabled ? textColor : "#9e9e9e"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.bold: true
                            }

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
                        color: textColor
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
                                color: index % 2 === 0 ? "#3e3e3e" : "#2e2e2e"
                                border.color: borderColor
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: model.name
                                        color: textColor
                                        width: (parent.width - parent.spacing) * 0.4
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                    Text {
                                        text: model.value
                                        color: textColor
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
                                color: "#424242"
                                border.color: borderColor
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: "Имя"
                                        color: textColor
                                        font.bold: true
                                        width: (parent.width - parent.spacing) * 0.4
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: "Значение"
                                        color: textColor
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
                                if (closeDebugButton.pressed) {
                                    var c = Qt.darker("#d32f2f", 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (closeDebugButton.hovered) {
                                    var c = Qt.lighter("#d32f2f", 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return "#f44336"
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                            font.bold: true
                        }

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
            border.color: borderColor
            border.width: 2
            radius: 5
            color: panelColor

            Behavior on border.color {
                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 5
                TextArea {
                    id: otvet
                    text: "Вывод"
                    readOnly: true
                    color: textColor
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
                color: textColor
                placeholderTextColor: "#bdbdbd"
                font.pixelSize: 18
                hoverEnabled: true

                background: Rectangle {
                    id: vvodBg
                    anchors.fill: parent
                    border.color: vvod.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                    border.width: 2
                    radius: 8
                    color: "#2d2d2d"

                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                        if (sendButton.pressed) {
                            var c = Qt.darker(buttonColor, 1.25);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else if (sendButton.hovered) {
                            var c = Qt.lighter(buttonColor, 1.15);
                            return Qt.rgba(c.r, c.g, c.b, 1);
                        } else return buttonColor
                    }
                    border.color: borderColor
                    border.width: 1
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                    font.bold: true
                }
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
                            if (setDebugStartButton.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (setDebugStartButton.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return root.isDebugStart ? "#FF69B4" : buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 15

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: "О"
                        color: textColor
                        font.bold: true
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

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
                            id: blockCanvas
                            anchors.fill: parent
                            antialiasing: true
                            z: 0
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                const w = width, h = height, cx = w/2, cy = h/2, s = 20
                                ctx.beginPath()
                                var fillColor;
                                if (root.hovered) {
                                    fillColor = Qt.lighter(getBlockColor(root.blockType), 1.15);
                                } else {
                                    fillColor = getBlockColor(root.blockType);
                                }
                                ctx.fillStyle = fillColor;
                                ctx.strokeStyle = root.isDebugHighlighted ? "yellow" : (root.isDebugStart ? "#FF69B4" : borderColor)
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
                                    ctx.fillStyle = textColor
                                    ctx.font = "bold 20px Arial"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText(root.blockType === "начало" ? "Начало" : "Конец", cx, cy)
                                }
                            }

                            function getBlockColor(type) {
                                var colors = {
                                    "ввод": inputColor,
                                    "вывод": outputColor,
                                    "действие": actionColor,
                                    "усл": condColor,
                                    "счетчик": counterColor,
                                    "предусл": precondColor,
                                    "постусл": postcondColor,
                                    "начало": startColor,
                                    "конец": endColor
                                };
                                return colors[type] || actionColor;
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
                            color: textColor
                            placeholderTextColor: "#757575"
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
                            color: textColor
                            placeholderTextColor: "#757575"
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
                                        color: textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterVarField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "i"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1
                                            radius: 4

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "Шаг:"
                                        color: textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterStepField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "1"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1
                                            radius: 4

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
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
                                        color: textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterFromField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "0"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1
                                            radius: 4

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: "До:"
                                        color: textColor
                                        font.pixelSize: 26
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterToField
                                        enabled: !main.debugMode
                                        width: 70
                                        placeholderText: "10"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 26
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1
                                            radius: 4

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
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
                                        if (addAboveButton.pressed) {
                                            var c = Qt.darker(buttonColor, 1.25);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else if (addAboveButton.hovered) {
                                            var c = Qt.lighter(buttonColor, 1.15);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else return buttonColor
                                    }
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 3

                                    Behavior on color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.fillStyle = textColor;
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
                                        if (addBelowButton.pressed) {
                                            var c = Qt.darker(buttonColor, 1.25);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else if (addBelowButton.hovered) {
                                            var c = Qt.lighter(buttonColor, 1.15);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else return buttonColor
                                    }
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 3

                                    Behavior on color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.fillStyle = textColor;
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
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerCounter ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                            if (counterActivateBtn.pressed) {
                                                var c = Qt.darker(buttonColor, 1.25);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else if (counterActivateBtn.hovered) {
                                                var c = Qt.lighter(buttonColor, 1.15);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else return main.activeContainer === centerContainerCounter ? "#9c27b0" : buttonColor
                                        }
                                        border.color: borderColor
                                        border.width: 1
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on border.color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: textColor
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

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
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainer ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                            if (cycleActivateBtn.pressed) {
                                                var c = Qt.darker(buttonColor, 1.25);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else if (cycleActivateBtn.hovered) {
                                                var c = Qt.lighter(buttonColor, 1.15);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else return main.activeContainer === centerContainer ? "#9c27b0" : buttonColor
                                        }
                                        border.color: borderColor
                                        border.width: 1
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on border.color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: textColor
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

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
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === leftContainer ? "#9c27b0" : borderColor)
                                    border.width: root.isDebugHighlighted ? 4 : 2
                                    radius: 5
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                                if (leftActivateBtn.pressed) {
                                                    var c = Qt.darker(buttonColor, 1.25);
                                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                                } else if (leftActivateBtn.hovered) {
                                                    var c = Qt.lighter(buttonColor, 1.15);
                                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                                } else return main.activeContainer === leftContainer ? "#9c27b0" : buttonColor
                                            }
                                            border.color: borderColor
                                            border.width: 1
                                            radius: width / 2

                                            Behavior on color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            color: textColor
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 18
                                            font.bold: true
                                        }

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
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === rightContainer ? "#9c27b0" : borderColor)
                                    border.width: root.isDebugHighlighted ? 4 : 2
                                    radius: 5
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                                if (rightActivateBtn.pressed) {
                                                    var c = Qt.darker(buttonColor, 1.25);
                                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                                } else if (rightActivateBtn.hovered) {
                                                    var c = Qt.lighter(buttonColor, 1.15);
                                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                                } else return main.activeContainer === rightContainer ? "#9c27b0" : buttonColor
                                            }
                                            border.color: borderColor
                                            border.width: 1
                                            radius: width / 2

                                            Behavior on color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            color: textColor
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 18
                                            font.bold: true
                                        }

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
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerPost ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
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
                                            if (postActivateBtn.pressed) {
                                                var c = Qt.darker(buttonColor, 1.25);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else if (postActivateBtn.hovered) {
                                                var c = Qt.lighter(buttonColor, 1.15);
                                                return Qt.rgba(c.r, c.g, c.b, 1);
                                            } else return main.activeContainer === centerContainerPost ? "#9c27b0" : buttonColor
                                        }
                                        border.color: borderColor
                                        border.width: 1
                                        radius: width / 2

                                        Behavior on color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on border.color {
                                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: textColor
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 18
                                        font.bold: true
                                    }

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

    // Окно настроек (отдельное)
    Window {
        id: settingsWindow
        title: "Настройки"
        width: 300
        height: 100
        modality: Qt.NonModal
        color: panelColor
        visible: false

        Rectangle {
            anchors.fill: parent
            color: parent.color

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Button {
                    text: "Палитра цветов"
                    width: parent.width
                    height: 50

                    background: Rectangle {
                        color: {
                            if (parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 8

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }

                    onClicked: {
                        paletteWindow.show()
                    }
                }
            }
        }
    }

    // Окно палитры цветов (отдельное)
    Window {
        id: paletteWindow
        title: "Палитра цветов"
        width: 450
        height: 600
        modality: Qt.NonModal
        color: panelColor
        visible: false

        Rectangle {
            anchors.fill: parent
            color: parent.color

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentHeight: paletteColumn.height + 20
                clip: true

                Column {
                    id: paletteColumn
                    width: parent.width - 20
                    spacing: 10

                    Text {
                        text: "Основные цвета:"
                        color: textColor
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Button {
                        text: "Сменить цвет текста"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "text"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет бордеров"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "border"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопок"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "button"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет фона"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "background"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет областей"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "panel"
                            colorPicker.open()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 2
                        color: borderColor

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        text: "Цвета кнопок спавна блоков:"
                        color: textColor
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Ввод'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "input"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Вывод'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "output"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Действие'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "action"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Счетчик'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "counter"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Предусловие'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "precond"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Постусловие'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "postcond"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Условие'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "cond"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Начало'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "start"
                            colorPicker.open()
                        }
                    }

                    Button {
                        text: "Сменить цвет кнопки 'Конец'"
                        width: parent.width
                        height: 40

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            colorPicker.currentTarget = "end"
                            colorPicker.open()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 2
                        color: borderColor

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    Button {
                        text: "Сбросить все цвета"
                        width: parent.width
                        height: 50

                        background: Rectangle {
                            color: {
                                if (parent.pressed) {
                                    var c = Qt.darker(buttonColor, 1.25);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else if (parent.hovered) {
                                    var c = Qt.lighter(buttonColor, 1.15);
                                    return Qt.rgba(c.r, c.g, c.b, 1);
                                } else return buttonColor
                            }
                            border.color: borderColor
                            border.width: 1
                            radius: 8

                            Behavior on color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }

                        onClicked: {
                            resetAllColors()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: miniBlockShapeItem
        Canvas {
            id: miniCanvas
            property string blockType: "действие"
            antialiasing: true
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height, cx = w/2, cy = h/2, s = 5
                ctx.beginPath()
                ctx.fillStyle = getBlockColor(blockType)
                ctx.strokeStyle = borderColor
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
                    "ввод": inputColor,
                    "вывод": outputColor,
                    "действие": actionColor,
                    "усл": condColor,
                    "счетчик": counterColor,
                    "предусл": precondColor,
                    "постусл": postcondColor,
                    "начало": startColor,
                    "конец": endColor
                };
                return colors[type] || actionColor;
            }

            Connections {
                target: main
                function onInputColorChanged() { if (blockType === "ввод") miniCanvas.requestPaint() }
                function onOutputColorChanged() { if (blockType === "вывод") miniCanvas.requestPaint() }
                function onActionColorChanged() { if (blockType === "действие") miniCanvas.requestPaint() }
                function onCondColorChanged() { if (blockType === "усл") miniCanvas.requestPaint() }
                function onCounterColorChanged() { if (blockType === "счетчик") miniCanvas.requestPaint() }
                function onPrecondColorChanged() { if (blockType === "предусл") miniCanvas.requestPaint() }
                function onPostcondColorChanged() { if (blockType === "постусл") miniCanvas.requestPaint() }
                function onStartColorChanged() { if (blockType === "начало") miniCanvas.requestPaint() }
                function onEndColorChanged() { if (blockType === "конец") miniCanvas.requestPaint() }
                function onBorderColorChanged() { miniCanvas.requestPaint() }
            }
        }
    }
}
