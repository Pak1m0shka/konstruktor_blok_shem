import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import myObrabotka
import QtQuick.Dialogs

Window {
    id: main
    width: 1000
    height: 700
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: qsTr("Построй алгоритм по задаче")
    color: "#121212"
    property Item activeContainer: container
    property Item activeToggle: null
    property string selectedBlockType: "действие"
    property bool debugMode: false
    property int currentDebugBlock: -1
    property bool canStepBack: false
    property bool canStepForward: true

    Obrabotka {
        id: myObrabotka
        onNeedUserInput: {
            console.log("QML: Получен запрос на ввод")
            otvet.text = otvet.text + "\n" + "QML: Получен запрос на ввод"
        }
        onInputProcessed: {
            console.log("ответ вернулся")
        }
        onVivod: {
            console.log("ответ есть")
            console.log(otvet_cpp)
            otvet.text = otvet.text + "\n" + otvet_cpp
        }
        onDebugging_peremennie: {
            console.log("Получены переменные от C++ для отображения")
            console.log("Данные (peremennie - QVariantMap):", peremennie)

            variablesModel.clear();

            if (peremennie && typeof peremennie === 'object') {
                var keys = Object.keys(peremennie);
                for (var i = 0; i < keys.length; i++) {
                    var name = keys[i];
                    var value = peremennie[name];
                    console.log("Добавляем переменную:", name, "=", value);
                    variablesModel.append({ name: name, value: value });
                }
            } else {
                console.warn("peremennie не является объектом:", peremennie);
            }
        }

        onHighlightBlock: {
            console.log("Получен сигнал highlightBlock с индексом:", blockIndex);
            currentDebugBlock = blockIndex;
            updateBlockHighlight();
        }

        onDebugHistoryChanged: {
            console.log("История отладки изменилась, можно шагать назад:", canStepBack, "можно шагать вперед:", canStepForward);
            main.canStepBack = canStepBack;
            main.canStepForward = canStepForward;
        }

        onDebugFinished: {
            console.log("Отладка завершена");
            main.debugMode = false;
            variablesModel.clear();
            updateBlockHighlight();
            currentDebugBlock = -1;
        }

        onAlgorithmLoaded: {
            console.log("Получен сигнал algorithmLoaded, количество блоков:", algorithm.length)
            if (algorithm && algorithm.length > 0) {
                loadAlgorithm(algorithm, container)
                information_save.text = "Алгоритм успешно загружен"
                information_save.open()
            }
        }

        onErrorOccurred: {
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

            Button {
                text: main.debugMode ? "Закончить отладку" : "Отладка"
                Shortcut {
                     sequence: "F6"
                     onActivated: {
                         if (main.debugMode) {
                             myObrabotka.stopDebugging();
                             main.debugMode = false;
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
                    color: main.debugMode ? "#9c27b0" : "#ab47bc"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
                onClicked: {
                    if (main.debugMode) {
                        myObrabotka.stopDebugging();
                        main.debugMode = false;
                    } else {
                        main.debugMode = true;
                        console.log("Режим отладки включен");
                        collectData(2);
                    }
                }
            }

            Button {
                text: "Запуск"
                onClicked: collectData(1)
                Shortcut { sequence: "F1"; onActivated: collectData(1) }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                background: Rectangle {
                    color: "#4caf50"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
            }

            Button {
                text: "Сохранить"
                Shortcut { sequence: "F2"; onActivated: saveFileDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                background: Rectangle {
                    color: "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
                onClicked: saveFileDialog.open()
            }

            Button {
                text: "Открыть"
                Shortcut { sequence: "F3"; onActivated: openFileDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                background: Rectangle {
                    color: "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
                onClicked: openFileDialog.open()
            }

            Button {
                text: "Новый алгоритм"
                Shortcut { sequence: "F4"; onActivated: newAlgorithmDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 180
                background: Rectangle {
                    color: "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
                onClicked: newAlgorithmDialog.open()
            }

            Button {
                text: "Справка"
                Shortcut { sequence: "F5"; onActivated: helpDialog.open() }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                background: Rectangle {
                    color: "#ab47bc"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
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
                    color: "#bdbdbd"
                    border.color: "#9e9e9e"
                    border.width: 1
                    radius: 5
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
                        color: "black"
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 18
                    }
                }
                delegate: ItemDelegate {
                    width: parent.width
                    height: 45
                    highlighted: ListView.isCurrentItem
                    background: Rectangle {
                        color: highlighted ? "#e0e0e0" : "#bdbdbd"
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
                            color: "black"
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
                        ctx.fillStyle = "black"
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width / 2, height)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }

            Button {
                id: inputBtn
                text: "Ввод"
                onClicked: createBlock("ввод")
                Shortcut { sequence: "F7"; onActivated: createBlock("ввод") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#ba68c8"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Ввод"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: outputBtn
                text: "Вывод"
                onClicked: createBlock("вывод")
                Shortcut { sequence: "F8"; onActivated: createBlock("вывод") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#4db6ac"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Вывод"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: actionBtn
                text: "Действие"
                onClicked: createBlock("действие")
                Shortcut { sequence: "F9"; onActivated: createBlock("действие") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "#64b5f6"
                    radius: 5
                }
                contentItem: Text {
                    text: "Действие"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: counterBtn
                text: "Счетчик"
                onClicked: createBlock("счетчик")
                Shortcut { sequence: "F10"; onActivated: createBlock("счетчик") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#ef5350"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Счетчик"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: precondBtn
                text: "Предусл"
                onClicked: createBlock("предусл")
                Shortcut { sequence: "F11"; onActivated: createBlock("предусл") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#ffb74d"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Предусл"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: postcondBtn
                text: "Постусл"
                onClicked: createBlock("постусл")
                Shortcut { sequence: "F12"; onActivated: createBlock("постусл") }
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#ce93d8"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Постусл"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: condBtn
                text: "Усл"
                onClicked: createBlock("усл")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
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
                            ctx.fillStyle = "#81c784"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Усл"
                    color: "black"
                    font.bold: true
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: startBtn
                text: "Начало"
                onClicked: createBlock("начало")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.ellipse(5, 5, w - 10, h - 10)
                            ctx.closePath()
                            ctx.fillStyle = "#64b5f6"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"

                            ctx.stroke()
                            ctx.fillStyle = "black"
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Начало", cx, cy)
                        }
                    }
                }
                contentItem: Item {}
            }

            Button {
                id: endBtn
                text: "Конец"
                onClicked: createBlock("конец")
                Layout.preferredHeight: 50
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: "transparent"
                    Canvas {
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width, h = height
                            var cx = w / 2, cy = h / 2
                            ctx.beginPath()
                            ctx.ellipse(5, 5, w - 10, h - 10)
                            ctx.closePath()
                            ctx.fillStyle = "#ffb74d"
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"

                            ctx.stroke()
                            ctx.fillStyle = "black"
                            ctx.font = "bold 20px Arial"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Конец", cx, cy)
                        }
                    }
                }
                contentItem: Item {}
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
                border.color: main.activeContainer === container ? "#9c27b0" : "#424242"
                border.width: 2
                radius: 5
                color: "#1e1e1e"

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
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 5
                        width: 35
                        height: 35
                        text: "A"
                        background: Rectangle {
                            color: main.activeContainer === container ? "#9c27b0" : "#424242"
                            radius: width / 2
                            border.color: "white"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                            font.bold: true
                        }
                        scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }
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
                color: "#2d2d2d"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "Панель отладки"
                        color: "#e0e0e0"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        Button {
                            text: "Назад"
                            enabled: main.debugMode && main.canStepBack
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
                                color: parent.enabled ? "#616161" : "#424242"
                                radius: 5
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "#e0e0e0" : "#757575"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                            }
                            onClicked: {
                                if (main.debugMode && main.canStepBack) {
                                    console.log("Отладка: Шаг назад (кнопка)");
                                    myObrabotka.debugStepBack();
                                }
                            }
                        }

                        Button {
                            text: "Вперёд"
                            enabled: main.debugMode && main.canStepForward
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
                                color: parent.enabled ? "#616161" : "#424242"
                                radius: 5
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "#e0e0e0" : "#757575"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
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
                        color: "#bdbdbd"
                        font.pixelSize: 18
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
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: model.name
                                        color: "#e0e0e0"
                                        width: (parent.width - parent.spacing) * 0.4
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: model.value
                                        color: "#bdbdbd"
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
                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 5
                                    anchors.rightMargin: 5
                                    spacing: 10
                                    Text {
                                        text: "Имя"
                                        color: "#e0e0e0"
                                        font.bold: true
                                        width: (parent.width - parent.spacing) * 0.4
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: "Значение"
                                        color: "#e0e0e0"
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
                        text: "Закрыть"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 120
                        background: Rectangle {
                            color: "#d32f2f"
                            radius: 5
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 18
                        }
                        onClicked: {
                            myObrabotka.stopDebugging();
                            main.debugMode = false;
                            console.log("Режим отладки выключен через кнопку закрытия");
                            variablesModel.clear();
                            currentDebugBlock = -1;
                            updateBlockHighlight();
                        }
                    }
                }
            }
        }

        // === Область вывода ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            border.color: "#424242"
            border.width: 2
            radius: 5
            color: "#1e1e1e"

            ScrollView {
                anchors.fill: parent
                anchors.margins: 5
                TextArea {
                    id: otvet
                    text: "Вывод"
                    color: "#e0e0e0"
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
                color: "#e0e0e0"
                placeholderTextColor: "#bdbdbd"
                font.pixelSize: 18
                background: Rectangle {
                    anchors.fill: parent
                    border.color: "#424242"
                    border.width: 2
                    radius: 5
                    color: "#2d2d2d"
                }
                Keys.onReturnPressed: myObrabotka.userInputReceived(vvod.text)
                Keys.onEnterPressed: myObrabotka.userInputReceived(vvod.text)
            }

            Button {
                text: "Отправить"
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                onClicked: myObrabotka.userInputReceived(vvod.text)
                Shortcut { sequence: "Return"; onActivated: myObrabotka.userInputReceived(vvod.text) }
                Shortcut { sequence: "Enter"; onActivated: myObrabotka.userInputReceived(vvod.text) }
                background: Rectangle {
                    color: parent.down ? "#1e88e5" : "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
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
            "blockType": type
        })
        console.log("Создан блок типа:", type, "в контейнере:", main.activeContainer)
    }

    function insertBlockAfter(referenceBlock, type) {
        var parentContainer = referenceBlock.parent;
        if (!parentContainer) {
            console.warn("Не найден родительский контейнер для вставки");
            return;
        }
        console.log("--- Начало вставки блока (метод отложенного перемещения) ---");
        console.log("Ссылочный блок:", referenceBlock.blockType);
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
        console.log("Индекс ссылочного блока:", referenceIndex);
        var tempContainer = Qt.createQmlObject('import QtQuick 2.15; Item {}', main, "tempContainerForInsert");
        console.log("Перемещение блоков после индекса", referenceIndex, "во временный контейнер...");
        var blocksToMoveCount = parentContainer.children.length - 1;
        for (var j = blocksToMoveCount; j > referenceIndex; j--) {
            var blockToMove = parentContainer.children[j];
            if (blockToMove) {
                blockToMove.parent = tempContainer;
                console.log("  -> Перемещен блок индекс", j, ":", blockToMove.blockType || "неизвестный");
            }
        }
        console.log("Создание нового блока типа:", type);
        var newBlock = spisok.createObject(parentContainer, { blockType: type });
        if (!newBlock) {
            console.error("Ошибка при создании нового блока!");
            var tempChildrenCount = tempContainer.children.length;
            for (var tc = 0; tc < tempChildrenCount; tc++) {
                 tempContainer.children[0].parent = parentContainer;
            }
            tempContainer.destroy();
            return;
        }
        console.log("Новый блок создан:", newBlock.blockType);
        console.log("Перемещение блоков обратно из временного контейнера...");
        var tempChildrenCountFinal = tempContainer.children.length;
        for (var k = 0; k < tempChildrenCountFinal; k++) {
            var blockToRestore = tempContainer.children[0];
            if (blockToRestore) {
                blockToRestore.parent = parentContainer;
                console.log("  -> Восстановлен блок:", blockToRestore.blockType || "неизвестный");
            }
        }
        tempContainer.destroy();
        console.log("Временный контейнер уничтожен.");
        console.log("Финальный порядок в parentContainer:");
        for(var logIdx = 0; logIdx < parentContainer.children.length; logIdx++) {
            console.log("  Индекс", logIdx, ":", parentContainer.children[logIdx].blockType || "неизвестный");
        }
        console.log("--- Вставка блока завершена (метод отложенного перемещения) ---");
    }

    function insertBlockBefore(referenceBlock, type) {
        var parentContainer = referenceBlock.parent;
        if (!parentContainer) {
            console.warn("Не найден родительский контейнер для вставки");
            return;
        }
        console.log("--- Начало вставки блока ПЕРЕД (метод отложенного перемещения) ---");
        console.log("Ссылочный блок:", referenceBlock.blockType);
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
        console.log("Индекс ссылочного блока:", referenceIndex);
        var tempContainer = Qt.createQmlObject('import QtQuick 2.15; Item {}', main, "tempContainerForInsert");
        console.log("Перемещение блоков начиная с индекса", referenceIndex, "во временный контейнер...");
        var blocksToMoveCount = parentContainer.children.length - 1;
        for (var j = blocksToMoveCount; j >= referenceIndex; j--) {
            var blockToMove = parentContainer.children[j];
            if (blockToMove) {
                blockToMove.parent = tempContainer;
                console.log("  -> Перемещен блок индекс", j, ":", blockToMove.blockType || "неизвестный");
            }
        }
        console.log("Создание нового блока типа:", type);
        var newBlock = spisok.createObject(parentContainer, { blockType: type });
        if (!newBlock) {
            console.error("Ошибка при создании нового блока!");
            var tempChildrenCount = tempContainer.children.length;
            for (var tc = 0; tc < tempChildrenCount; tc++) {
                 tempContainer.children[0].parent = parentContainer;
            }
            tempContainer.destroy();
            return;
        }
        console.log("Новый блок создан:", newBlock.blockType);
        console.log("Перемещение блоков обратно из временного контейнера...");
        var tempChildrenCountFinal = tempContainer.children.length;
        for (var k = 0; k < tempChildrenCountFinal; k++) {
            var blockToRestore = tempContainer.children[0];
            if (blockToRestore) {
                blockToRestore.parent = parentContainer;
                console.log("  -> Восстановлен блок:", blockToRestore.blockType || "неизвестный");
            }
        }
        tempContainer.destroy();
        console.log("Временный контейнер уничтожен.");
        console.log("Финальный порядок в parentContainer:");
        for(var logIdx = 0; logIdx < parentContainer.children.length; logIdx++) {
            console.log("  Индекс", logIdx, ":", parentContainer.children[logIdx].blockType || "неизвестный");
        }
        console.log("--- Вставка блока ПЕРЕД завершена (метод отложенного перемещения) ---");
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
            property int blockIndex: {
                if (!parent) return -1;
                for (var i = 0; i < parent.children.length; i++) {
                    if (parent.children[i] === root) {
                        return i;
                    }
                }
                return -1;
            }

            function getData() {
                function processContainer(cont) {
                    if (!cont || !cont.children) return []
                    var items = []
                    for (var i = 0; i < cont.children.length; i++) {
                        var child = cont.children[i]
                        if (typeof child.getData === "function") {
                            var data = child.getData()
                            if (data.type === "усл") {
                                items.push([data.type, data.input, data.trueBranch || [], data.falseBranch || []])
                            } else if (["счетчик", "предусл", "постусл"].includes(data.type)) {
                                items.push([data.type, data.input, data.loopBody || []])
                            } else {
                                items.push([data.type, data.input])
                            }
                        }
                    }
                    return items
                }

                var result;
                if (root.blockType === "усл") {
                    result = {
                        type: root.blockType,
                        input: inputFieldDiamond.text.trim(),
                        trueBranch: processContainer(leftContainer),
                        falseBranch: processContainer(rightContainer)
                    };
                } else if (root.blockType === "счетчик") {
                    result = {
                        type: root.blockType,
                        input: counterVarField.text.trim() + " = " +
                               counterFromField.text.trim() + " to " +
                               counterToField.text.trim() + " step " +
                               counterStepField.text.trim(),
                        loopBody: processContainer(centerContainerCounter)
                    };
                } else if (root.blockType === "предусл") {
                    result = {
                        type: root.blockType,
                        input: inputFieldDiamond.text.trim(),
                        loopBody: processContainer(centerContainer)
                    };
                } else if (root.blockType === "постусл") {
                    result = {
                        type: root.blockType,
                        input: inputFieldDiamond.text.trim(),
                        loopBody: processContainer(centerContainerPost)
                    };
                } else {
                    result = {
                        type: root.blockType,
                        input: inputField.text.trim()
                    };
                }
                return result;
            }

            Column {
                id: contentColumn
                width: Math.max(parent.width, childrenRect.width)
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
                            ctx.fillStyle = getBlockColor(root.blockType)
                            ctx.strokeStyle = root.isDebugHighlighted ? "yellow" : "#e0e0e0"
                            ctx.lineWidth = root.isDebugHighlighted ? 3 : 2
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
                                ctx.fillStyle = "black"
                                ctx.font = "bold 22px Arial"
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.fillText(root.blockType === "начало" ? "Начало" : "Конец", cx, cy)
                            }
                        }

                        function getBlockColor(type) {
                            return ({
                                "ввод": "#ba68c8",
                                "вывод": "#4db6ac",
                                "действие": "#64b5f6",
                                "усл": "#81c784",
                                "счетчик": "#ef5350",
                                "предусл": "#ffb74d",
                                "постусл": "#ce93d8",
                                "начало": "#64b5f6",
                                "конец": "#ffb74d"
                            })[type] || "#64b5f6"
                        }
                    }

                    TextField {
                        id: inputField
                        anchors.centerIn: parent
                        width: parent.width - 30
                        visible: !["начало", "конец", "счетчик", "усл", "предусл", "постусл"].includes(root.blockType)
                        placeholderText: ({
                            "ввод": "Введите переменные для ввода...",
                            "вывод": "Введите данные для вывода...",
                            "действие": "Введите действие...",
                        })[root.blockType] || "Введите данные..."
                        color: "black"
                        placeholderTextColor: "#757575"
                        selectByMouse: true
                        font.pixelSize: 26
                        font.bold: true
                        background: Rectangle {
                            color: "transparent";
                            border.width: 0
                        }
                    }

                    TextField {
                        id: inputFieldDiamond
                        visible: ["усл", "предусл", "постусл"].includes(root.blockType)
                        anchors.centerIn: parent
                        width: parent.width * 0.8
                        height: parent.height * 0.7
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        placeholderText: "Введите условие..."
                        color: "black"
                        placeholderTextColor: "#757575"
                        selectByMouse: true
                        font.pixelSize: 26
                        font.bold: true
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
                                    color: "black"
                                    font.pixelSize: 26
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                                TextField {
                                    id: counterVarField
                                    width: 70
                                    placeholderText: "i"
                                    color: "black"
                                    placeholderTextColor: "#9e9e9e"
                                    selectByMouse: true
                                    font.pixelSize: 26
                                    font.bold: true
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: "black"
                                        border.width: 1
                                        radius: 2
                                    }
                                }
                            }

                            Row {
                                spacing: 8
                                Text {
                                    text: "Шаг:"
                                    color: "black"
                                    font.pixelSize: 26
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                                TextField {
                                    id: counterStepField
                                    width: 70
                                    placeholderText: "1"
                                    color: "black"
                                    placeholderTextColor: "#9e9e9e"
                                    selectByMouse: true
                                    font.pixelSize: 26
                                    font.bold: true
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: "black"
                                        border.width: 1
                                        radius: 2
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
                                    color: "black"
                                    font.pixelSize: 26
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                                TextField {
                                    id: counterFromField
                                    width: 70
                                    placeholderText: "0"
                                    color: "black"
                                    placeholderTextColor: "#9e9e9e"
                                    selectByMouse: true
                                    font.pixelSize: 26
                                    font.bold: true
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: "black"
                                        border.width: 1
                                        radius: 2
                                    }
                                }
                            }

                            Row {
                                spacing: 8
                                Text {
                                    text: "До:"
                                    color: "black"
                                    font.pixelSize: 26
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }
                                TextField {
                                    id: counterToField
                                    width: 70
                                    placeholderText: "10"
                                    color: "black"
                                    placeholderTextColor: "#9e9e9e"
                                    selectByMouse: true
                                    font.pixelSize: 26
                                    font.bold: true
                                    background: Rectangle {
                                        color: "transparent"
                                        border.color: "black"
                                        border.width: 1
                                        radius: 2
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
                            width: 30
                            height: 30
                            background: Rectangle {
                                color: "#bdbdbd"
                                border.color: "#9e9e9e"
                                border.width: 1
                                radius: 3
                                Canvas {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.fillStyle = "black";
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
                            width: 30
                            height: 30
                            background: Rectangle {
                                color: "#bdbdbd"
                                border.color: "#9e9e9e"
                                border.width: 1
                                radius: 3
                                Canvas {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.fillStyle = "black";
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
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            root.destroy()
                            console.log("Блок удалён правым кликом")
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        enabled: !inputField.activeFocus && !inputFieldDiamond.activeFocus
                        onDoubleTapped: {
                            root.destroy()
                            console.log("Блок удалён двойным кликом")
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
                            width: Math.max(400, centerContainerCounter.childrenRect.width + 40)
                            height: Math.max(160, centerContainerCounter.childrenRect.height + 50)
                            border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerCounter ? "#9c27b0" : "#388e3c")
                            border.width: root.isDebugHighlighted ? 4 : 2
                            radius: 5
                            color: "transparent"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Column {
                                id: centerContainerCounter
                                width: Math.max(350, childrenRect.width)
                                anchors.centerIn: parent
                                spacing: 10
                            }

                            Button {
                                id: counterActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                                width: 35
                                height: 35
                                text: "A"
                                background: Rectangle {
                                    color: main.activeContainer === centerContainerCounter ? "#9c27b0" : "#424242"
                                    radius: width / 2
                                    border.color: "white"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100 } }
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
                            width: Math.max(400, centerContainer.childrenRect.width + 40)
                            height: Math.max(160, centerContainer.childrenRect.height + 50)
                            border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainer ? "#9c27b0" : "#388e3c")
                            border.width: root.isDebugHighlighted ? 4 : 2
                            radius: 5
                            color: "transparent"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Column {
                                id: centerContainer
                                width: Math.max(350, childrenRect.width)
                                anchors.centerIn: parent
                                spacing: 10
                            }

                            Button {
                                id: cycleActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                                width: 35
                                height: 35
                                text: "A"
                                background: Rectangle {
                                    color: main.activeContainer === centerContainer ? "#9c27b0" : "#424242"
                                    radius: width / 2
                                    border.color: "white"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100 } }
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
                                width: Math.max(280, leftContainer.childrenRect.width + 40)
                                height: Math.max(160, leftContainer.childrenRect.height + 50)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === leftContainer ? "#9c27b0" : "#388e3c")
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"

                                Column {
                                    id: leftContainer
                                    width: Math.max(250, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10
                                }

                                Button {
                                    id: leftActivateBtn
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 35
                                    height: 35
                                    text: "A"
                                    background: Rectangle {
                                        color: main.activeContainer === leftContainer ? "#9c27b0" : "#424242"
                                        radius: width / 2
                                        border.color: "white"
                                        border.width: 1
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
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
                                width: Math.max(280, rightContainer.childrenRect.width + 40)
                                height: Math.max(160, rightContainer.childrenRect.height + 50)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === rightContainer ? "#9c27b0" : "#388e3c")
                                border.width: root.isDebugHighlighted ? 4 : 2
                                radius: 5
                                color: "transparent"

                                Column {
                                    id: rightContainer
                                    width: Math.max(250, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10
                                }

                                Button {
                                    id: rightActivateBtn
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5
                                    width: 35
                                    height: 35
                                    text: "A"
                                    background: Rectangle {
                                        color: main.activeContainer === rightContainer ? "#9c27b0" : "#424242"
                                        radius: width / 2
                                        border.color: "white"
                                        border.width: 1
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
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
                            width: Math.max(400, centerContainerPost.childrenRect.width + 40)
                            height: Math.max(160, centerContainerPost.childrenRect.height + 50)
                            border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerPost ? "#9c27b0" : "#388e3c")
                            border.width: root.isDebugHighlighted ? 4 : 2
                            radius: 5
                            color: "transparent"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Column {
                                id: centerContainerPost
                                width: Math.max(350, childrenRect.width)
                                anchors.centerIn: parent
                                spacing: 10
                            }

                            Button {
                                id: postActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                                width: 35
                                height: 35
                                text: "A"
                                background: Rectangle {
                                    color: main.activeContainer === centerContainerPost ? "#9c27b0" : "#424242"
                                    radius: width / 2
                                    border.color: "white"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100 } }
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

    function collectData(a) {
        function processContainer(cont) {
            if (!cont || !cont.children) return []
            var items = []
            for (var i = 0; i < cont.children.length; i++) {
                var child = cont.children[i]
                if (typeof child.getData === "function") {
                    var data = child.getData()
                    if (data.type === "усл") {
                        items.push([data.type, data.input, data.trueBranch, data.falseBranch])
                    } else if (["счетчик", "предусл", "постусл"].includes(data.type)) {
                        items.push([data.type, data.input, data.loopBody])
                    } else {
                        items.push([data.type, data.input])
                    }
                }
            }
            return items
        }
        var data = processContainer(container)
        console.log("📤 Структура алгоритма:")
        data.forEach(item => {
            console.log(`  [${item[0]}] ${item[1]}`)
            if (item[0] === "усл") {
                console.log("    Да:", item[2])
                console.log("    Нет:", item[3])
            } else if (["счетчик", "предусл", "постусл"].includes(item[0])) {
                console.log("    Тело:", item[2])
            }
        })
        if(a === 1){
        myObrabotka.myPriem(data)
        return data
        } else if(a === 2){
            myObrabotka.startDebugging(data)
            return data
        }
    }

    function updateBlockHighlight() {
        for (var i = 0; i < container.children.length; i++) {
            var block = container.children[i];
            if (block && block.hasOwnProperty("isDebugHighlighted")) {
                block.isDebugHighlighted = (i === currentDebugBlock);

                if (block.hasOwnProperty("centerContainerPost")) {
                    updateNestedBlockHighlight(block.centerContainerPost, i);
                }
                if (block.hasOwnProperty("centerContainer")) {
                    updateNestedBlockHighlight(block.centerContainer, i);
                }
                if (block.hasOwnProperty("centerContainerCounter")) {
                    updateNestedBlockHighlight(block.centerContainerCounter, i);
                }
                if (block.hasOwnProperty("leftContainer")) {
                    updateNestedBlockHighlight(block.leftContainer, i);
                }
                if (block.hasOwnProperty("rightContainer")) {
                    updateNestedBlockHighlight(block.rightContainer, i);
                }
            }
        }
    }

    function updateNestedBlockHighlight(container, parentIndex) {
        if (!container || !container.children) return;
        for (var i = 0; i < container.children.length; i++) {
            var block = container.children[i];
            if (block && block.hasOwnProperty("isDebugHighlighted")) {
                block.isDebugHighlighted = false;

                // Рекурсивно обновляем вложенные контейнеры
                if (block.hasOwnProperty("centerContainerPost")) {
                    updateNestedBlockHighlight(block.centerContainerPost, i);
                }
                if (block.hasOwnProperty("centerContainer")) {
                    updateNestedBlockHighlight(block.centerContainer, i);
                }
                if (block.hasOwnProperty("centerContainerCounter")) {
                    updateNestedBlockHighlight(block.centerContainerCounter, i);
                }
                if (block.hasOwnProperty("leftContainer")) {
                    updateNestedBlockHighlight(block.leftContainer, i);
                }
                if (block.hasOwnProperty("rightContainer")) {
                    updateNestedBlockHighlight(block.rightContainer, i);
                }
            }
        }
    }

    onCurrentDebugBlockChanged: {
        updateBlockHighlight();
    }

    onDebugModeChanged: {
        if (!debugMode) {
            currentDebugBlock = -1;
            updateBlockHighlight();
            canStepBack = false;
            canStepForward = true;
        }
    }

    Component {
        id: miniBlockShapeItem
        Item {
            id: miniShapeItem
            property alias blockType: miniShapeCanvas.blockType

            Canvas {
                id: miniShapeCanvas
                anchors.fill: parent
                property string blockType: "действие"

                function getBlockColor(type) {
                    return ({
                        "ввод": "#ba68c8",
                        "вывод": "#4db6ac",
                        "действие": "#64b5f6",
                        "усл": "#81c784",
                        "счетчик": "#ef5350",
                        "предусл": "#ffb74d",
                        "постусл": "#ce93d8",
                        "начало": "#64b5f6",
                        "конец": "#ffb74d"
                    })[type] || "#64b5f6"
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height, cx = w/2, cy = h/2, s = 2
                    ctx.beginPath()
                    ctx.fillStyle = getBlockColor(miniShapeCanvas.blockType)
                    ctx.strokeStyle = "#e0e0e0"
                    ctx.lineWidth = 1
                    if (["ввод", "вывод"].includes(miniShapeCanvas.blockType)) {
                        ctx.moveTo(s, 0);
                        ctx.lineTo(w, 0);
                        ctx.lineTo(w-s, h);
                        ctx.lineTo(0, h);
                    } else if (["усл", "предусл", "постусл"].includes(miniShapeCanvas.blockType)) {
                        ctx.moveTo(cx, 2);
                        ctx.lineTo(w-2, cy);
                        ctx.lineTo(cx, h-2);
                        ctx.lineTo(2, cy);
                    } else if (miniShapeCanvas.blockType === "счетчик") {
                        const hex = 3
                        ctx.moveTo(hex, 0);
                        ctx.lineTo(w-hex, 0);
                        ctx.lineTo(w, h/2)
                        ctx.lineTo(w-hex, h);
                        ctx.lineTo(hex, h);
                        ctx.lineTo(0, h/2);
                    } else if (["начало", "конец"].includes(miniShapeCanvas.blockType)) {
                        ctx.ellipse(1, 1, w-2, h-2);
                    } else {
                        ctx.rect(0, 0, w, h);
                    }
                    ctx.closePath();
                    ctx.fill();
                    ctx.stroke();
                    if (["начало", "конец"].includes(miniShapeCanvas.blockType)) {
                        ctx.fillStyle = "black";
                        ctx.font = "bold 9px Arial";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText(miniShapeCanvas.blockType === "начало" ? "Н" : "К", cx, cy);
                    }
                }
                onBlockTypeChanged: requestPaint()
            }
        }
    }

    // Диалог сохранения файла
    Dialog {
        id: saveFileDialog
        title: "Сохранить алгоритм"
        width: 600
        height: 200
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: filePathField.forceActiveFocus()

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: saveFileDialog.borderColor; width: 1 }

            Label {
                text: saveFileDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: saveFileDialog.borderColor; width: 1 }
        }

        property string filePath: ""

        contentItem: Column {
            spacing: 15
            width: parent.width

            Row {
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                TextField {
                    id: filePathField
                    width: parent.width - browseButton.width - 10
                    placeholderText: "Введите путь к файлу или выберите через обзор"
                    text: saveFileDialog.filePath
                    onTextChanged: saveFileDialog.filePath = text
                    color: "#e0e0e0"
                    placeholderTextColor: "#bdbdbd"
                    font.pixelSize: 14
                    background: Rectangle {
                        anchors.fill: parent
                        border.color: "#424242"
                        border.width: 2
                        radius: 5
                        color: "#2d2d2d"
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            saveButton.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: browseButton
                    text: "Обзор"
                    width: 100
                    height: filePathField.height
                    background: Rectangle {
                        color: parent.pressed ? saveFileDialog.buttonPressed
                               : parent.hovered ? saveFileDialog.buttonHover
                               : saveFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : saveFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }
                    contentItem: Text {
                        text: browseButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: fileSaveDialog.open()
                }
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: saveButton
                    text: "Сохранить"
                    width: 120
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.right: cancelSaveButton

                    background: Rectangle {
                        color: parent.pressed ? saveFileDialog.buttonPressed
                               : parent.hovered ? saveFileDialog.buttonHover
                               : saveFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : saveFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: saveButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (filePathField.text.trim() === "") {
                            errorDialog.text = "Введите путь к файлу"
                            errorDialog.open()
                            return
                        }

                        var algorithm = collectData(1)
                        var success = myObrabotka.saveAlgorithmToFile(algorithm, filePathField.text)
                        if (success) {
                            information_save.open()
                            saveFileDialog.close()
                        } else {
                            errorDialog.text = "Ошибка при сохранении файла"
                            errorDialog.open()
                        }
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: cancelSaveButton
                    text: "Отмена"
                    width: 120
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.left: saveButton

                    background: Rectangle {
                        color: parent.pressed ? saveFileDialog.buttonPressed
                               : parent.hovered ? saveFileDialog.buttonHover
                               : saveFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : saveFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: cancelSaveButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: saveFileDialog.close()

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        FileDialog {
            id: fileSaveDialog
            title: "Сохранить файл"
            fileMode: FileDialog.SaveFile
            nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]

            onAccepted: {
                filePathField.text = selectedFile
            }
        }
    }

    // Диалог открытия файла
    Dialog {
        id: openFileDialog
        title: "Открыть алгоритм"
        width: 600
        height: 200
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: openFilePathField.forceActiveFocus()

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: openFileDialog.borderColor; width: 1 }

            Label {
                text: openFileDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: openFileDialog.borderColor; width: 1 }
        }

        property string filePath: ""

        contentItem: Column {
            spacing: 15
            width: parent.width

            Row {
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                TextField {
                    id: openFilePathField
                    width: parent.width - openBrowseButton.width - 10
                    placeholderText: "Введите путь к файлу или выберите через обзор"
                    text: openFileDialog.filePath
                    onTextChanged: openFileDialog.filePath = text
                    color: "#e0e0e0"
                    placeholderTextColor: "#bdbdbd"
                    font.pixelSize: 14
                    background: Rectangle {
                        anchors.fill: parent
                        border.color: "#424242"
                        border.width: 2
                        radius: 5
                        color: "#2d2d2d"
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            openButton.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: openBrowseButton
                    text: "Обзор"
                    width: 100
                    height: openFilePathField.height
                    background: Rectangle {
                        color: parent.pressed ? openFileDialog.buttonPressed
                               : parent.hovered ? openFileDialog.buttonHover
                               : openFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : openFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }
                    contentItem: Text {
                        text: openBrowseButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: fileOpenDialog.open()
                }
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: openButton
                    text: "Открыть"
                    width: 120
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.right: cancelOpenButton

                    background: Rectangle {
                        color: parent.pressed ? openFileDialog.buttonPressed
                               : parent.hovered ? openFileDialog.buttonHover
                               : openFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : openFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: openButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (openFilePathField.text.trim() === "") {
                            errorDialog.text = "Введите путь к файлу"
                            errorDialog.open()
                            return
                        }

                        console.log("Пытаемся загрузить файл:", openFilePathField.text)
                        var algorithm = myObrabotka.loadAlgorithmFromFile(openFilePathField.text)
                        console.log("Загруженный алгоритм:", algorithm)

                        if (algorithm && algorithm.length > 0) {
                            loadAlgorithm(algorithm, container)
                            openFileDialog.close()
                            information_save.text = "Алгоритм успешно загружен"
                            information_save.open()
                        } else {
                            errorDialog.text = "Не удалось загрузить файл. Файл поврежден или имеет неверный формат."
                            errorDialog.open()
                        }
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: cancelOpenButton
                    text: "Отмена"
                    width: 120
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.left: openButton

                    background: Rectangle {
                        color: parent.pressed ? openFileDialog.buttonPressed
                               : parent.hovered ? openFileDialog.buttonHover
                               : openFileDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : openFileDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: cancelOpenButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: openFileDialog.close()

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        FileDialog {
            id: fileOpenDialog
            title: "Открыть файл"
            fileMode: FileDialog.OpenFile
            nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]

            onAccepted: {
                openFilePathField.text = selectedFile
            }
        }
    }

    // Диалог нового алгоритма
    Dialog {
        id: newAlgorithmDialog
        title: "Новый алгоритм"
        width: 400
        height: 180
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: yesButtonNew.forceActiveFocus()

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: newAlgorithmDialog.borderColor; width: 1 }

            Label {
                text: newAlgorithmDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: newAlgorithmDialog.borderColor; width: 1 }
        }

        contentItem: Column {
            spacing: 20
            width: parent.width

            Text {
                width: parent.width
                text: "Вы уверены, что хотите создать новый алгоритм? Все несохраненные данные будут потеряны."
                wrapMode: Text.Wrap
                color: "white"
                font.bold: true
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: yesButtonNew
                    text: "Да"
                    width: 100
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.right: noButtonNew

                    background: Rectangle {
                        color: parent.pressed ? newAlgorithmDialog.buttonPressed
                               : parent.hovered ? newAlgorithmDialog.buttonHover
                               : newAlgorithmDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : newAlgorithmDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: yesButtonNew.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        clearContainer(container)
                        newAlgorithmDialog.close()
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }

                Button {
                    id: noButtonNew
                    text: "Нет"
                    width: 100
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.left: yesButtonNew

                    background: Rectangle {
                        color: parent.pressed ? newAlgorithmDialog.buttonPressed
                               : parent.hovered ? newAlgorithmDialog.buttonHover
                               : newAlgorithmDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : newAlgorithmDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: noButtonNew.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: newAlgorithmDialog.close()

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }

    // Диалог справки
    Dialog {
        id: helpDialog
        title: "Справка"
        width: 500
        height: 300
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: okButtonHelp.forceActiveFocus()

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: helpDialog.borderColor; width: 1 }

            Label {
                text: helpDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: helpDialog.borderColor; width: 1 }
        }

        contentItem: Column {
            spacing: 20
            width: parent.width

            ScrollView {
                width: parent.width - 20
                height: 200
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                TextArea {
                    width: parent.width
                    text: "Краткая справка по использованию:\n\n" +
                          "F1 - Запуск алгоритма\n" +
                          "F2 - Сохранить алгоритм\n" +
                          "F3 - Открыть алгоритм\n" +
                          "F4 - Новый алгоритм\n" +
                          "F5 - Справка\n" +
                          "F6 - Режим отладки\n\n" +
                          "Для создания блоков используйте кнопки на панели инструментов или комбинации клавиш F7-F12.\n\n" +
                          "Для удаления блока используйте правый клик или двойной левый клик."
                    color: "white"
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    readOnly: true
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }

            Button {
                id: okButtonHelp
                text: "OK"
                width: 100
                height: 35
                anchors.horizontalCenter: parent.horizontalCenter
                focusPolicy: Qt.StrongFocus

                background: Rectangle {
                    color: parent.pressed ? helpDialog.buttonPressed
                           : parent.hovered ? helpDialog.buttonHover
                           : helpDialog.buttonColor
                    border {
                        color: parent.activeFocus ? "red" : helpDialog.borderColor
                        width: 1
                        }
                    radius: 5
                }

                contentItem: Text {
                    text: okButtonHelp.text
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: helpDialog.close()

                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        clicked()
                        event.accepted = true
                    }
                }
            }
        }
    }

    Dialog {
        id: resizeDialog
        title: "Изменить размер сетки"
        width: 300
        height: 180
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: {
            sizeInput.forceActiveFocus()
            sizeInput.selectAll()
        }

        property int newRows: 0
        property int newCols: 0

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: resizeDialog.borderColor; width: 1 }

            Label {
                text: resizeDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: resizeDialog.borderColor; width: 1 }
        }

        contentItem: Column {
            spacing: 15
            width: parent.width

            TextField {
                id: sizeInput
                placeholderText: "Количество столбцов (1-90)"
                font.pixelSize: 14
                validator: IntValidator { bottom: 1; top: 90 }
                inputMethodHints: Qt.ImhDigitsOnly
                color: "#FFFFFF"
                font.bold: true
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter

                background: Rectangle {
                    color: parent.pressed ? resizeDialog.buttonPressed
                           : parent.hovered ? resizeDialog.buttonHover
                           : resizeDialog.buttonColor
                    border {
                        color: parent.activeFocus ? "red" : resizeDialog.borderColor
                        width: 1
                    }
                    radius: 5
                }

                onTextChanged: {
                    resizeDialog.newCols = parseInt(text) || 1
                    resizeDialog.newRows = parseInt(text) || 1
                    if (text !== "") {
                        var num = parseInt(text);
                        if (isNaN(num)) {
                            text = "";
                        } else if (num < 1) {
                            text = "1";
                        } else if (num > 90) {
                            text = "90";
                        }
                    }
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        yesButton5.forceActiveFocus()
                        event.accepted = true
                    }
                    else if (event.key === Qt.Key_Right) {
                        noButton5.forceActiveFocus()
                        event.accepted = true
                    }
                    else if (event.key === Qt.Key_Tab) {
                        noButton5.forceActiveFocus()
                        event.accepted = true
                    }
                    else if (event.key === Qt.Key_Backtab) {
                        yesButton5.forceActiveFocus()
                        event.accepted = true
                    }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        yesButton5.forceActiveFocus()
                        event.accepted = true
                    }
                }

                onActiveFocusChanged: if(activeFocus) selectAll()
            }

            Label {
                text: "Текущий размер: 0x0"
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: yesButton5
                    text: "Да"
                    width: 90
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.right: noButton5

                    background: Rectangle {
                        color: parent.pressed ? resizeDialog.buttonPressed
                               : parent.hovered ? resizeDialog.buttonHover
                               : resizeDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : resizeDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: yesButton5.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        const size = parseInt(sizeInput.text)
                        if (size >= 1 && size <= 1000) {
                            resizeDialog.close()
                        } else {
                            errorDialog.text = "Некорректный размер!"
                            errorDialog.open()
                        }
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                        }
                    }
                }

                Button {
                    id: noButton5
                    text: "Нет"
                    width: 90
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.left: yesButton5

                    background: Rectangle {
                        color: parent.pressed ? resizeDialog.buttonPressed
                               : parent.hovered ? resizeDialog.buttonHover
                               : resizeDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : resizeDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: noButton5.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: resizeDialog.close()

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: errorDialog
        property string text: ""
        width: 300
        height: 150
        title:"ошибка"
        modal: true
        dim: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay
        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        onOpened: {
            yesButton4.forceActiveFocus()
        }
        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: errorDialog.borderColor; width: 1 }

            Label {
                text: errorDialog.title
                Layout.alignment: Qt.AlignHCenter
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: errorDialog.borderColor; width: 1 }
        }

        property string resultText: ""
        contentItem: ColumnLayout {
                    spacing: 15
                    width: parent.width
                    height: parent.height

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        Label {
                              Layout.alignment: Qt.AlignHCenter
                               anchors.fill: parent
                               text: errorDialog.text
                               wrapMode: Text.Wrap
                               font.bold: true
                               font.pixelSize: 16
                               color: "white"
                           }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        Button {
                            id: yesButton4
                            text: "ок"
                            font.bold: true
                            font.pixelSize: 14
                            width: 110
                            height: 35
                            focusPolicy: Qt.StrongFocus
                            contentItem: Text {
                                    text: yesButton4.text
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                            background: Rectangle {
                                color: yesButton4.hovered ? errorDialog.buttonHover
                                       : errorDialog.buttonColor
                                border {
                                   color: yesButton4.activeFocus ? "red" : errorDialog.borderColor
                                    width: 2
                                }
                                radius: 5
                            }

                            onClicked: errorDialog.close()

                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    clicked()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }

    Dialog{
        id:information_save
        width: 300
        height: 150
        title:"Попытка сохранения файла сделана!"
        modal: true
        dim: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay
        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        onOpened: {
            yesButton2.forceActiveFocus()
        }
        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: information_save.borderColor; width: 1 }

            Label {
                text: information_save.title
                Layout.alignment: Qt.AlignHCenter
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: information_save.borderColor; width: 1 }
        }

        property string resultText: ""
        contentItem: ColumnLayout {
                    spacing: 15
                    width: parent.width
                    height: parent.height

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        Label {
                              Layout.alignment: Qt.AlignHCenter
                               anchors.fill: parent
                               text: "Проверьте наличие файла!"
                               wrapMode: Text.Wrap
                               font.bold: true
                               font.pixelSize: 16
                               color: "white"
                           }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        Button {
                            id: yesButton2
                            text: "ок"
                            font.bold: true
                            font.pixelSize: 14
                            width: 110
                            height: 35
                            focusPolicy: Qt.StrongFocus
                            contentItem: Text {
                                    text: yesButton2.text
                                    color: "#FFFFFF"
                                    font.bold: true
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                            background: Rectangle {
                                color: yesButton2.hovered ? information_save.buttonHover
                                       : information_save.buttonColor
                                border {
                                   color: yesButton2.activeFocus ? "red" : information_save.borderColor
                                    width: 2
                                }
                                radius: 5
                            }

                            onClicked: information_save.close()

                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    clicked()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
    }

    Dialog {
        id: confirmDialog
        title: "Подтверждение"
        width: 300
        height: 140
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: Overlay.overlay

        property color buttonColor: "#000080"
        property color buttonHover: "#191970"
        property color buttonPressed: "#4B0082"
        property color borderColor: "#FFFFFF"

        focus: true
        onOpened: yesButton.forceActiveFocus()

        Keys.onPressed: {
            switch(event.key) {
            case Qt.Key_Left:
                if (noButton.activeFocus) yesButton.forceActiveFocus()
                event.accepted = true
                break

            case Qt.Key_Right:
                if (yesButton.activeFocus) noButton.forceActiveFocus()
                event.accepted = true
                break

            case Qt.Key_Tab:
                            if (yesButton.activeFocus) noButton.forceActiveFocus()
                            else yesButton.forceActiveFocus()
                            event.accepted = true
                            break
            }
        }

        header: Rectangle {
            color: "#000000"
            height: 40
            radius: 5
            border { color: confirmDialog.borderColor; width: 1 }

            Label {
                text: confirmDialog.title
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.centerIn: parent
            }
        }

        background: Rectangle {
            color: "#000000"
            radius: 10
            border { color: confirmDialog.borderColor; width: 1 }
        }

        property string message: ""
        property var onConfirmed: function() {}

        contentItem: Column {
            spacing: 15
            width: parent.width

            Text {
                width: parent.width
                text: confirmDialog.message
                wrapMode: Text.Wrap
                color: "white"
                font.bold: true
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: yesButton
                    text: "Да"
                    width: 90
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.right: noButton

                    background: Rectangle {
                        color: parent.pressed ? confirmDialog.buttonPressed
                               : parent.hovered ? confirmDialog.buttonHover
                               : confirmDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : confirmDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: yesButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if(typeof confirmDialog.onConfirmed === "function") {
                            confirmDialog.onConfirmed()
                        }
                        confirmDialog.close()
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }

                    onActiveFocusChanged: {
                        if(activeFocus) forceActiveFocus()
                    }
                }

                Button {
                    id: noButton
                    text: "Нет"
                    width: 90
                    height: 35
                    focusPolicy: Qt.StrongFocus
                    KeyNavigation.left: yesButton

                    background: Rectangle {
                        color: parent.pressed ? confirmDialog.buttonPressed
                               : parent.hovered ? confirmDialog.buttonHover
                               : confirmDialog.buttonColor
                        border {
                            color: parent.activeFocus ? "red" : confirmDialog.borderColor
                            width: 1
                        }
                        radius: 5
                    }

                    contentItem: Text {
                        text: noButton.text
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: confirmDialog.close()

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            clicked()
                            event.accepted = true
                        }
                    }

                    onActiveFocusChanged: {
                        if(activeFocus) forceActiveFocus()
                    }
                }
            }
        }

        Component.onCompleted: console.log("Dialog initialized")
        onActiveFocusChanged: console.log("Dialog focus:", activeFocus)
    }

    // Функция загрузки алгоритма в интерфейс
    function loadAlgorithm(algorithm, targetContainer) {
        clearContainer(targetContainer)

        function processBlock(blockData, container) {
            if (!blockData || blockData.length < 2) return

            var type = blockData[0]
            var content = blockData[1]

            // Создаем блок
            var newBlock = spisok.createObject(container, {"blockType": type})
            if (!newBlock) return

            // Заполняем содержимое
            if (newBlock.inputField && type !== "счетчик" && type !== "предусл" && type !== "постусл") {
                newBlock.inputField.text = content
            } else if (newBlock.inputFieldDiamond && ["усл", "предусл", "постусл"].includes(type)) {
                newBlock.inputFieldDiamond.text = content
            } else if (newBlock.counterVarField && type === "счетчик") {
                var parts = content.split(/=|to|step/).map(function(part) {
                    return part.trim()
                })
                if (parts.length >= 4) {
                    newBlock.counterVarField.text = parts[0]
                    newBlock.counterFromField.text = parts[1]
                    newBlock.counterToField.text = parts[2]
                    newBlock.counterStepField.text = parts[3] || "1"
                }
            }

            // Обрабатываем вложенные блоки
            if (type === "усл" && blockData.length >= 4) {
                var trueBranch = blockData[2]
                var falseBranch = blockData[3]

                if (trueBranch && trueBranch.length > 0 && newBlock.leftContainer) {
                    trueBranch.forEach(function(nestedBlock) {
                        processBlock(nestedBlock, newBlock.leftContainer)
                    })
                }

                if (falseBranch && falseBranch.length > 0 && newBlock.rightContainer) {
                    falseBranch.forEach(function(nestedBlock) {
                        processBlock(nestedBlock, newBlock.rightContainer)
                    })
                }
            } else if (type === "счетчик" && blockData.length >= 3) {
                var loopBody = blockData[2]
                if (loopBody && loopBody.length > 0 && newBlock.centerContainerCounter) {
                    loopBody.forEach(function(nestedBlock) {
                        processBlock(nestedBlock, newBlock.centerContainerCounter)
                    })
                }
            } else if (type === "предусл" && blockData.length >= 3) {
                var loopBody = blockData[2]
                if (loopBody && loopBody.length > 0 && newBlock.centerContainer) {
                    loopBody.forEach(function(nestedBlock) {
                        processBlock(nestedBlock, newBlock.centerContainer)
                    })
                }
            } else if (type === "постусл" && blockData.length >= 3) {
                var loopBody = blockData[2]
                if (loopBody && loopBody.length > 0 && newBlock.centerContainerPost) {
                    loopBody.forEach(function(nestedBlock) {
                        processBlock(nestedBlock, newBlock.centerContainerPost)
                    })
                }
            }
        }

        algorithm.forEach(function(blockData) {
            processBlock(blockData, targetContainer)
        })
    }

    function clearContainer(container) {
        if (!container || !container.children) return

        var children = []
        for (var i = 0; i < container.children.length; i++) {
            if (container.children[i] && container.children[i].blockType !== undefined) {
                children.push(container.children[i])
            }
        }

        for (var j = 0; j < children.length; j++) {
            if (children[j] && children[j].destroy) {
                children[j].destroy()
            }
        }
    }
}
