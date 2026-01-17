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
    property int currentDebugBlockId: -1
    property bool canStepBack: false
    property bool canStepForward: true
    property int blockIdCounter: 0

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
                    variablesModel.append({ name: name, value: value });
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

            Button {
                text: main.debugMode ? "Закончить отладку" : "Отладка"
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
        newBlock.z = referenceIndex + 2; // Move it above the reference block initially
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

            function highlightInSelfAndChildren(targetId) {
                // Шаг 1: Проверить, является ли текущий блок целью
                if (root.uniqueId === targetId) {
                    root.isDebugHighlighted = true;
                } else {
                    root.isDebugHighlighted = false;
                }

                // Шаг 2: Рекурсивно вызвать эту же функцию для дочерних блоков в контейнерах
                function highlightInContainer(cont) {
                    if (!cont) return;
                    for (var i = 0; i < cont.children.length; i++) {
                        var block = cont.children[i];
                        if (block && typeof block.highlightInSelfAndChildren === 'function') {
                            block.highlightInSelfAndChildren(targetId);
                        }
                    }
                }

                // Проверяем все возможные контейнеры
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
            myObrabotka.startDebugging(data)
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

    onCurrentDebugBlockIdChanged: {
        updateBlockHighlight()
    }

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
        currentFolder: shortcuts.home
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
        currentFolder: shortcuts.home
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            var path = openFileDialog.file.toString().substring(Qt.platform.os === "windows" ? 8 : 7)
            myObrabotka.loadAlgorithmFromFile(path)
        }
    }

    Dialog {
        id: newAlgorithmDialog
        title: "Новый алгоритм"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        width: 300
        height: 150
        contentItem: Text {
            text: "Вы уверены, что хотите создать новый алгоритм? Все несохраненные данные будут утеряны."
            wrapMode: Text.WordWrap
        }
        onAccepted: {
            container.destroyChildren()
            main.blockIdCounter = 0
            console.log("Создан новый пустой алгоритм")
        }
    }

    Dialog {
        id: errorDialog
        title: "Ошибка"
        modal: true
        standardButtons: Dialog.Ok
        property alias text: errorText.text
        contentItem: Text {
            id: errorText
            wrapMode: Text.WordWrap
        }
    }
    Dialog {
        id: helpDialog
        title: "Справка"
        modal: true
        standardButtons: Dialog.Ok
        width: 600
        height: 400
        contentItem: ScrollView {
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
            }
        }
    }

    MessageDialog {
        id: information_save
        title: "Информация"
        text: "Алгоритм успешно сохранен."
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
                ctx.strokeStyle = "#424242"
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
