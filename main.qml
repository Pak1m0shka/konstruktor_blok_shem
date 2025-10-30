import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import myObrabotka

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
    property string selectedBlockType: "действие" // По умолчанию выбрано "действие"

    Obrabotka {
        id: myObrabotka
        onNeedUserInput: {
            console.log("QML: Получен запрос на ввод")
        }
        onInputProcessed: {
            console.log("ответ вернулся")
        }
        onVivod: {
            console.log("ответ есть")
            console.log(otvet_cpp)
            otvet.text = otvet_cpp
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
                text: "Запуск (F1)"
                onClicked: collectData()
                Shortcut { sequence: "F1"; onActivated: collectData() }
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#4caf50" // Более светлый зеленый
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black" // Черный текст
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70)) // Увеличенный размер
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                text: "Сохранить (F2)"
                Shortcut { sequence: "F2"; onActivated: console.log("Сохранить") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#42a5f5" // Более светлый синий
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                text: "Открыть (F3)"
                Shortcut { sequence: "F3"; onActivated: console.log("Открыть") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                text: "Новый алгоритм (F4)"
                Shortcut { sequence: "F4"; onActivated: console.log("Новый алгоритм") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#42a5f5"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                text: "Справка (F5)"
                Shortcut { sequence: "F5"; onActivated: console.log("Справка") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "#ab47bc" // Более светлый фиолетовый
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }
        }

        // === Панель кнопок спавна (2 ряд) ===
        RowLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 5

            // === Выпадающий список для выбора типа блока с фигурками ===
            ComboBox {
                id: blockTypeSelector
                Layout.preferredWidth: 200
                Layout.preferredHeight: 40
                // Используем ListModel для хранения типа и отображаемого имени
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
                // Используем тип из модели для selectedBlockType
                onCurrentIndexChanged: {
                    if (blockTypeSelector.currentIndex >= 0 && blockTypeSelector.currentIndex < blockTypeSelector.model.count) {
                        main.selectedBlockType = blockTypeSelector.model.get(blockTypeSelector.currentIndex).type;
                        console.log("Выбран тип блока (по модели):", main.selectedBlockType);
                    }
                }
                currentIndex: 2 // "действие" по умолчанию
                background: Rectangle {
                    color: "#bdbdbd" // Более светлый серый
                    border.color: "#9e9e9e"
                    border.width: 1
                    radius: 5
                }
                // Отображение выбранного элемента в свернутом состоянии
                contentItem: Row {
                    leftPadding: 10
                    spacing: 5
                    // Миниатюра выбранного блока
                    Loader {
                        id: selectedBlockMiniShapeLoader
                        width: 20
                        height: 20
                        sourceComponent: miniBlockShapeItem
                        onLoaded: {
                            // Устанавливаем тип при первой загрузке
                            item.blockType = main.selectedBlockType;
                        }
                        // Обновляем тип при его изменении
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
                        // Получаем отображаемое имя из модели
                        text: {
                            var currentIdx = blockTypeSelector.currentIndex;
                            if (currentIdx >= 0 && currentIdx < blockTypeSelector.model.count) {
                                return blockTypeSelector.model.get(currentIdx).displayName || "";
                            }
                            return "";
                        }
                        color: "black" // Черный текст
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Math.max(14, Math.min(18, main.width / 65)) // Увеличенный размер
                    }
                }
                // Элементы выпадающего списка с фигурками
                delegate: ItemDelegate {
                    width: parent.width
                    height: 35 // Увеличиваем высоту для фигурки
                    highlighted: ListView.isCurrentItem
                    background: Rectangle {
                        color: highlighted ? "#e0e0e0" : "#bdbdbd" // Светлее при выделении
                    }
                    contentItem: Row {
                        spacing: 5
                        leftPadding: 5
                        // Миниатюра блока в списке
                        Loader {
                            width: 25
                            height: 25
                            sourceComponent: miniBlockShapeItem
                            onLoaded: {
                                // Устанавливаем тип из данных модели делегата
                                item.blockType = model.type;
                            }
                        }
                        Text {
                            text: model.displayName // Используем отображаемое имя из модели
                            color: "black" // Черный текст
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5
                            font.pixelSize: Math.max(14, Math.min(18, main.width / 65)) // Увеличенный размер
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
                        ctx.fillStyle = "black" // Черная стрелка
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width / 2, height)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }
            // === Конец ComboBox ===

            Button {
                id: inputBtn
                text: "Ввод (F6)"
                onClicked: createBlock("ввод")
                Shortcut { sequence: "F6"; onActivated: createBlock("ввод") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#ba68c8" // Более светлый фиолетовый
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Ввод"
                    color: "black" // Черный текст
                    font.bold: true
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70)) // Увеличенный размер
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: outputBtn
                text: "Вывод (F7)"
                onClicked: createBlock("вывод")
                Shortcut { sequence: "F7"; onActivated: createBlock("вывод") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#4db6ac" // Более светлый бирюзовый
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                        }
                    }
                }
                contentItem: Text {
                    text: "Вывод"
                    color: "black"
                    font.bold: true
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: actionBtn
                text: "Действие (F8)"
                onClicked: createBlock("действие")
                Shortcut { sequence: "F8"; onActivated: createBlock("действие") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
                    color: "#64b5f6" // Более светлый синий
                    radius: 5
                }
                contentItem: Text {
                    text: "Действие"
                    color: "black"
                    font.bold: true
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: counterBtn
                text: "Счетчик (F9)"
                onClicked: createBlock("счетчик")
                Shortcut { sequence: "F9"; onActivated: createBlock("счетчик") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#ef5350" // Более светлый красный
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
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: precondBtn
                text: "Предусл (F10)"
                onClicked: createBlock("предусл")
                Shortcut { sequence: "F10"; onActivated: createBlock("предусл") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#ffb74d"  // Более светлый оранжевый
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
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: postcondBtn
                text: "Постусл (F11)"
                onClicked: createBlock("постусл")
                Shortcut { sequence: "F11"; onActivated: createBlock("постусл") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#ce93d8"  // Более светлый фиолетовый
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
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: condBtn
                text: "Усл (F12)"
                onClicked: createBlock("усл")
                Shortcut { sequence: "F12"; onActivated: createBlock("усл") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#81c784"  // Более светлый зеленый
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
                    font.pixelSize: Math.max(12, Math.min(16, main.width / 70))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: startBtn
                text: "Начало (Shift+F1)"
                onClicked: createBlock("начало")
                Shortcut { sequence: "Shift+F1"; onActivated: createBlock("начало") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#64b5f6" // Более светлый синий
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                            // Текст "Начало"
                            ctx.fillStyle = "black" // Черный текст
                            ctx.font = "bold " + Math.max(12, Math.min(14, main.width / 80)) + "px Arial" // Увеличенный размер
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Начало", cx, cy)
                        }
                    }
                }
                contentItem: Item {}
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }

            Button {
                id: endBtn
                text: "Конец (Shift+F2)"
                onClicked: createBlock("конец")
                Shortcut { sequence: "Shift+F2"; onActivated: createBlock("конец") }
                Layout.preferredHeight: 40
                background: Rectangle {
                    implicitWidth: Math.max(60, main.width / 12)
                    implicitHeight: 40
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
                            ctx.fillStyle = "#ffb74d" // Более светлый оранжевый
                            ctx.fill()
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
                            ctx.stroke()
                            // Текст "Конец"
                            ctx.fillStyle = "black" // Черный текст
                            ctx.font = "bold " + Math.max(12, Math.min(14, main.width / 80)) + "px Arial" // Увеличенный размер
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText("Конец", cx, cy)
                        }
                    }
                }
                contentItem: Item {}
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
            }
        }

        // === Область алгоритма ===
        Rectangle {
            id: algorithmArea
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: container
                    width: parent.width
                    spacing: Math.max(5, Math.min(10, main.height / 100))
                    padding: Math.max(2, Math.min(5, main.height / 120))
                }

                // Кнопка активации основной области
                Button {
                    id: mainActivateBtn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Math.max(5, Math.min(10, main.width / 150))
                    width: Math.max(25, Math.min(35, main.width / 30))
                    height: Math.max(25, Math.min(35, main.width / 30))
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
                        font.pixelSize: Math.max(14, Math.min(20, main.width / 35)) // Увеличенный размер
                        font.bold: true
                    }
                    scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                    Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
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

                // Обработчик клика для создания блока по выбранному типу
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

        // === Область вывода ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(150, main.height / 4)
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
                    font.pixelSize: Math.max(14, Math.min(18, main.width / 65)) // Увеличенный размер
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
        }

        // === Панель ввода ===
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.max(5, Math.min(10, main.width / 100))

            TextField {
                id: vvod
                placeholderText: "Ввод"
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(35, Math.min(45, main.height / 18))
                color: "#e0e0e0"
                placeholderTextColor: "#bdbdbd" // Светлее серый
                font.pixelSize: Math.max(14, Math.min(18, main.width / 65)) // Увеличенный размер
                background: Rectangle {
                    anchors.fill: parent
                    border.color: "#424242"
                    border.width: 2
                    radius: 5
                    color: "#2d2d2d"
                }
                // Привязка Enter к отправке
                Keys.onReturnPressed: myObrabotka.userInputReceived(vvod.text)
                Keys.onEnterPressed: myObrabotka.userInputReceived(vvod.text)
            }

            Button {
                text: "Отправить (Enter)"
                Layout.preferredHeight: Math.max(35, Math.min(45, main.height / 18))
                Layout.preferredWidth: Math.max(80, Math.min(120, main.width / 10))
                onClicked: myObrabotka.userInputReceived(vvod.text)
                // Привязка Enter к кнопке
                Shortcut { sequence: "Return"; onActivated: myObrabotka.userInputReceived(vvod.text) }
                Shortcut { sequence: "Enter"; onActivated: myObrabotka.userInputReceived(vvod.text) }
                background: Rectangle {
                    color: parent.down ? "#1e88e5" : "#42a5f5" // Светлее синий
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "black" // Черный текст
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(14, Math.min(18, main.width / 65)) // Увеличенный размер
                }
                // scale: parent.pressed ? 0.9 : (parent.hovered ? 0.95 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
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

    // === Функция для вставки блока после указанного блока (метод отложенного перемещения) ===
    function insertBlockAfter(referenceBlock, type) {
        var parentContainer = referenceBlock.parent;
        if (!parentContainer) {
            console.warn("Не найден родительский контейнер для вставки");
            return;
        }
        console.log("--- Начало вставки блока (метод отложенного перемещения) ---");
        console.log("Ссылочный блок:", referenceBlock.blockType);
        // 1. Найти индекс ссылочного блока
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
        // 2. Создать временный контейнер для блоков, идущих после referenceBlock
        var tempContainer = Qt.createQmlObject('import QtQuick 2.15; Item {}', main, "tempContainerForInsert");
        // 3. Переместить все блоки с индексом > referenceIndex во временный контейнер
        //    Идем с конца, чтобы индексы не сбивались при перемещении
        console.log("Перемещение блоков после индекса", referenceIndex, "во временный контейнер...");
        var blocksToMoveCount = parentContainer.children.length - 1; // Последний индекс
        for (var j = blocksToMoveCount; j > referenceIndex; j--) {
            var blockToMove = parentContainer.children[j];
            if (blockToMove) {
                blockToMove.parent = tempContainer;
                console.log("  -> Перемещен блок индекс", j, ":", blockToMove.blockType || "неизвестный");
            }
        }
        // 4. Создать новый блок. Он добавится в конец parentContainer.
        console.log("Создание нового блока типа:", type);
        var newBlock = spisok.createObject(parentContainer, { blockType: type });
        if (!newBlock) {
            console.error("Ошибка при создании нового блока!");
            // Пытаемся вернуть перемещенные блоки, хотя ситуация критическая
            var tempChildrenCount = tempContainer.children.length;
            for (var tc = 0; tc < tempChildrenCount; tc++) {
                 tempContainer.children[0].parent = parentContainer; // Перемещаем обратно по одному
            }
            tempContainer.destroy();
            return;
        }
        console.log("Новый блок создан:", newBlock.blockType);
        // 5. Переместить блоки из временного контейнера обратно в parentContainer
        //    Они добавятся в конец, что и нужно для восстановления порядка.
        console.log("Перемещение блоков обратно из временного контейнера...");
        var tempChildrenCountFinal = tempContainer.children.length;
        for (var k = 0; k < tempChildrenCountFinal; k++) {
            // Всегда берем [0], так как после перемещения индексы в tempContainer сдвигаются
            var blockToRestore = tempContainer.children[0];
            if (blockToRestore) {
                blockToRestore.parent = parentContainer;
                console.log("  -> Восстановлен блок:", blockToRestore.blockType || "неизвестный");
            }
        }
        // 6. Уничтожить временный контейнер
        tempContainer.destroy();
        console.log("Временный контейнер уничтожен.");
        console.log("Финальный порядок в parentContainer:");
        for(var logIdx = 0; logIdx < parentContainer.children.length; logIdx++) {
            console.log("  Индекс", logIdx, ":", parentContainer.children[logIdx].blockType || "неизвестный");
        }
        console.log("--- Вставка блока завершена (метод отложенного перемещения) ---");
    }

    Component {
        id: spisok
        Item {
            id: root
            width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: contentColumn.implicitHeight
            property string blockType: "действие"

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
                        input: inputField.text.trim(), // Условие для блока "усл"
                        trueBranch: processContainer(leftContainer),
                        falseBranch: processContainer(rightContainer)
                    };
                } else if (root.blockType === "счетчик") {
                    // Для счетчика собираем данные из 4 полей
                    result = {
                        type: root.blockType,
                        // Формируем строку вида "var = from to to step step"
                        input: counterVarField.text.trim() + " = " +
                               counterFromField.text.trim() + " to " +
                               counterToField.text.trim() + " step " +
                               counterStepField.text.trim(),
                        loopBody: processContainer(centerContainerCounter) // Используем новый ID
                    };
                } else if (["предусл", "постусл"].includes(root.blockType)) {
                    result = {
                        type: root.blockType,
                        input: inputField.text.trim(), // Условие для пред/постусловия
                        loopBody: processContainer(centerContainer || centerContainerPost)
                    };
                } else {
                    // Для всех остальных блоков (ввод, вывод, действие, начало, конец)
                    result = {
                        type: root.blockType,
                        input: inputField.text.trim() // Обычный текст
                    };
                }
                return result;
            }

            Column {
                id: contentColumn
                width: parent.width
                spacing: Math.max(5, Math.min(10, main.height / 100))

                // === Постусловие (тело + условие внизу) ===
                Item {
                    id: postConditionWrapper
                    width: parent.width
                    height: visible ? postConditionContent.height + Math.max(10, Math.min(20, main.height / 60)) : 0
                    visible: root.blockType === "постусл"
                    clip: true

                    Column {
                        id: postConditionContent
                        width: parent.width
                        spacing: Math.max(5, Math.min(10, main.height / 100))

                        Rectangle {
                            width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Math.max(120, centerContainerPost.childrenRect.height + Math.max(25, Math.min(40, main.height / 25)))
                            border.color: main.activeContainer === centerContainerPost ? "#9c27b0" : "#388e3c"
                            border.width: 2
                            radius: 5
                            color: "transparent"

                            Column {
                                id: centerContainerPost
                                anchors.fill: parent
                                anchors.margins: Math.max(5, Math.min(10, main.width / 100))
                                spacing: Math.max(5, Math.min(10, main.height / 100))
                            }

                            // Кнопка активации для постусловия
                            Button {
                                id: postActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Math.max(3, Math.min(5, main.width / 150))
                                width: Math.max(20, Math.min(30, main.width / 35))
                                height: Math.max(20, Math.min(30, main.width / 35))
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
                                    font.pixelSize: Math.max(12, Math.min(18, main.width / 40)) // Увеличенный размер
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                                Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
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

                            // Обработчик клика для создания блока в постусловии
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

                // === Основная фигура блока ===
                Item {
                    id: shapeItem
                    width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: getDefaultHeight()

                    function getDefaultHeight() {
                        var baseHeight = 0;
                        switch (root.blockType) {
                            case "начало":
                            case "конец":
                                baseHeight = 60
                                break
                            case "предусл":
                            case "постусл":
                            case "усл":
                                baseHeight = 90
                                break
                            case "счетчик":
                                baseHeight = 70
                                break
                            default:
                                baseHeight = 50
                                break
                        }
                        return Math.max(baseHeight * 0.8, Math.min(baseHeight * 1.2, main.height / 12))
                    }

                    Canvas {
                        anchors.fill: parent
                        antialiasing: true
                        z: -1
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const w = width, h = height, cx = w/2, cy = h/2, s = Math.max(15, Math.min(25, h * 0.3))
                            ctx.beginPath()
                            ctx.fillStyle = getBlockColor(root.blockType)
                            ctx.strokeStyle = "#e0e0e0"
                            ctx.lineWidth = 2
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
                                const hex = Math.max(15, Math.min(25, h * 0.3))
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
                            // Добавляем текст для начала и конца
                            if (["начало", "конец"].includes(root.blockType)) {
                                ctx.fillStyle = "black" // Черный текст
                                ctx.font = "bold " + Math.max(14, Math.min(20, main.width / 55)) + "px Arial" // Увеличенный размер
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.fillText(root.blockType === "начало" ? "Начало" : "Конец", cx, cy)
                            }
                        }

                        function getBlockColor(type) {
                            // Используем более светлые цвета
                            return ({
                                "ввод": "#ba68c8",     // Светлый фиолетовый
                                "вывод": "#4db6ac",    // Светлый бирюзовый
                                "действие": "#64b5f6", // Светлый синий
                                "усл": "#81c784",      // Светлый зеленый
                                "счетчик": "#ef5350",  // Светлый красный
                                "предусл": "#ffb74d",  // Светлый оранжевый
                                "постусл": "#ce93d8",  // Светлый фиолетовый
                                "начало": "#64b5f6",   // Светлый синий
                                "конец": "#ffb74d"     // Светлый оранжевый
                            })[type] || "#64b5f6" // По умолчанию светлый синий
                        }
                    }

                    // TextField для обычных блоков
                    TextField {
                        id: inputField
                        anchors.centerIn: parent
                        width: parent.width - Math.max(15, Math.min(25, main.width / 40))
                        // Скрываем для счетчика, начало, конец
                        visible: !["начало", "конец", "счетчик"].includes(root.blockType)
                        placeholderText: ({
                            "ввод": "Введите переменные для ввода...",
                            "вывод": "Введите данные для вывода...",
                            "действие": "Введите действие...",
                            //"усл": "Введите условие...",
                            // "счетчик": "Введите параметры цикла...", // Убираем, так как используем отдельные поля
                           // "предусл": "Введите условие цикла...",
                            //"постусл": "Введите условие цикла..."
                        })//[root.blockType] || "Введите данные..."
                        color: "black" // Черный текст
                        placeholderTextColor: "#757575" // Светло-серый плейсхолдер
                        selectByMouse: true
                        font.pixelSize: Math.max(30, Math.min(18, main.width / 65)) // Увеличенный размер
                        font.bold: true // Жирный шрифт
                        background: Rectangle {
                            color: "transparent";
                            border.width: 0
                        }
                    }

                    // TextField для блоков "усл", "предусл", "постусл" (ромбы)
                    TextField {
                        id: inputFieldDiamond
                        visible: ["усл", "предусл", "постусл"].includes(root.blockType) // Показываем только для ромбов
                        anchors.centerIn: parent // Центрируем внутри ромба
                        // Уменьшаем ширину и высоту для лучшего вида внутри ромба
                        width: Math.max(parent.width * 0.27, Math.min(parent.width * 0.7, parent.width - 20)) // Ограниченная ширина
                        height: Math.max(parent.height * 0.17, Math.min(parent.height * 0.6, parent.height - 10)) // Ограниченная высота для кликабельности
                        horizontalAlignment: Text.AlignHCenter // Центрируем текст по горизонтали
                        verticalAlignment: Text.AlignVCenter // Центрируем текст по вертикали
                        placeholderText: ({
                            "усл": "Условие...",
                            "предусл": "Условие цикла...",
                            "постусл": "Условие цикла..."
                        })[root.blockType] || "Введите условие..."
                        color: "black" // Черный текст для ромбов
                        placeholderTextColor: "#757575"
                        selectByMouse: true
                        font.pixelSize: Math.max(30, Math.min(18, main.width / 65)) // Увеличенный размер
                        font.bold: true // Жирный шрифт
                        background: Rectangle {
                            color: "transparent";
                            border.width: 0
                        }
                    }


                    // === Специфическое содержимое для счетчика (внутри шестиугольника) ===
                    Row {
                        id: counterFieldsRow
                        anchors.centerIn: parent
                        spacing: Math.max(5, Math.min(10, main.width / 100))
                        visible: root.blockType === "счетчик" // Показываем только для счетчика

                        // Переменная
                        Row {
                            spacing: 2
                            Text {
                                text: "Переменная:"
                                color: "black" // Черный цвет для контраста на красном фоне
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85)) // Увеличенный размер
                                verticalAlignment: Text.AlignVCenter
                            }
                            TextField {
                                id: counterVarField
                                implicitWidth: Math.max(50, Math.min(60, main.width / 15))
                                placeholderText: "i"
                                color: "black"
                                placeholderTextColor: "#9e9e9e"
                                selectByMouse: true
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85)) // Увеличенный размер
                                font.bold: true // Жирный шрифт
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "black" // Черная рамка
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                        // От (From)
                        Row {
                            spacing: 2
                            Text {
                                text: "От:"
                                color: "black"
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                verticalAlignment: Text.AlignVCenter
                            }
                            TextField {
                                id: counterFromField
                                implicitWidth: Math.max(50, Math.min(60, main.width / 15))
                                placeholderText: "0"
                                color: "black"
                                placeholderTextColor: "#9e9e9e"
                                selectByMouse: true
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                font.bold: true // Жирный шрифт
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "black"
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                        // До (To)
                        Row {
                            spacing: 2
                            Text {
                                text: "До:"
                                color: "black"
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                verticalAlignment: Text.AlignVCenter
                            }
                            TextField {
                                id: counterToField
                                implicitWidth: Math.max(50, Math.min(60, main.width / 15))
                                placeholderText: "10"
                                color: "black"
                                placeholderTextColor: "#9e9e9e"
                                selectByMouse: true
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                font.bold: true // Жирный шрифт
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "black"
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                        // Шаг (Step)
                        Row {
                            spacing: 2
                            Text {
                                text: "Шаг:"
                                color: "black"
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                verticalAlignment: Text.AlignVCenter
                            }
                            TextField {
                                id: counterStepField
                                implicitWidth: Math.max(50, Math.min(60, main.width / 15))
                                placeholderText: "1"
                                color: "black"
                                placeholderTextColor: "#9e9e9e"
                                selectByMouse: true
                                font.pixelSize: Math.max(25, Math.min(14, main.width / 85))
                                font.bold: true // Жирный шрифт
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "black"
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                    }
                    // === Конец специфического содержимого для счетчика ===

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            root.destroy()
                            console.log("Блок удалён правым кликом")
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        enabled: !inputField.activeFocus && !inputFieldDiamond.activeFocus // Проверяем фокус обоих полей
                        onDoubleTapped: {
                            root.destroy()
                            console.log("Блок удалён двойным кликом")
                        }
                    }
                }

                // === Циклы: предусловие и счётчик ===
                Item {
                    id: cycleWrapper
                    width: parent.width
                    // Высота зависит от типа цикла
                    height: visible ? ((root.blockType === "счетчик") ? counterSpecificContent.height + Math.max(10, Math.min(20, main.height / 60)) : cycleContentDefault.height + Math.max(10, Math.min(20, main.height / 60))) : 0
                    visible: ["предусл", "счетчик"].includes(root.blockType)
                    clip: true

                    // === Содержимое для обычного цикла (предусловие) ===
                    Column {
                        id: cycleContentDefault
                        width: parent.width
                        spacing: Math.max(5, Math.min(10, main.height / 100))
                        visible: root.blockType !== "счетчик" // Показываем только для предусловия

                        Rectangle {
                            width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Math.max(120, centerContainer.childrenRect.height + Math.max(25, Math.min(40, main.height / 25)))
                            border.color: main.activeContainer === centerContainer ? "#9c27b0" : "#388e3c"
                            border.width: 2
                            radius: 5
                            color: "transparent"

                            Column {
                                id: centerContainer
                                anchors.fill: parent
                                anchors.margins: Math.max(5, Math.min(10, main.width / 100))
                                spacing: Math.max(5, Math.min(10, main.height / 100))
                            }

                            // Кнопка активации для предусловия
                            Button {
                                id: cycleActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Math.max(3, Math.min(5, main.width / 150))
                                width: Math.max(20, Math.min(30, main.width / 35))
                                height: Math.max(20, Math.min(30, main.width / 35))
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
                                    font.pixelSize: Math.max(12, Math.min(18, main.width / 40)) // Увеличенный размер
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                                Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
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

                            // Обработчик клика для создания блока в цикле
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
                    // === Конец содержимого для обычного цикла ===

                    // === Специфическое содержимое для счетчика (тело цикла) ===
                    Column {
                        id: counterSpecificContent
                        width: parent.width
                        spacing: Math.max(5, Math.min(10, main.height / 100))
                        visible: root.blockType === "счетчик" // Показываем только для счетчика

                        // Область тела цикла счетчика
                        Rectangle {
                            width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: Math.max(120, centerContainerCounter.childrenRect.height + Math.max(25, Math.min(40, main.height / 25)))
                            border.color: main.activeContainer === centerContainerCounter ? "#9c27b0" : "#388e3c"
                            border.width: 2
                            radius: 5
                            color: "transparent"

                            Column {
                                id: centerContainerCounter // Новый ID для контейнера счетчика
                                anchors.fill: parent
                                anchors.margins: Math.max(5, Math.min(10, main.width / 100))
                                spacing: Math.max(5, Math.min(10, main.height / 100))
                            }

                            // Кнопка активации для тела счетчика
                            Button {
                                id: counterActivateBtn
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Math.max(3, Math.min(5, main.width / 150))
                                width: Math.max(20, Math.min(30, main.width / 35))
                                height: Math.max(20, Math.min(30, main.width / 35))
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
                                    font.pixelSize: Math.max(12, Math.min(18, main.width / 40)) // Увеличенный размер
                                    font.bold: true
                                }
                                scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                                Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
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

                            // Обработчик клика для создания блока в теле счетчика
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
                    // === Конец специфического содержимого для счетчика ===
                }

                // === Ветвление: да / нет ===
                Item {
                    id: conditionWrapper
                    width: parent.width
                    height: visible ? conditionContent.height + Math.max(10, Math.min(20, main.height / 60)) : 0
                    visible: root.blockType === "усл"
                    clip: true

                    Column {
                        id: conditionContent
                        width: parent.width
                        spacing: Math.max(5, Math.min(10, main.height / 100))

                        Row {
                            width: parent.width - Math.max(10, Math.min(20, parent.width / 30))
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Math.max(5, Math.min(10, main.width / 80))

                            Rectangle {
                                width: (parent.width - parent.spacing) * 0.48
                                height: Math.max(120, leftContainer.childrenRect.height + Math.max(25, Math.min(40, main.height / 25)))
                                border.color: main.activeContainer === leftContainer ? "#9c27b0" : "#388e3c"
                                border.width: 2
                                radius: 5
                                color: "transparent"

                                Column {
                                    id: leftContainer
                                    anchors.fill: parent
                                    anchors.margins: Math.max(5, Math.min(10, main.width / 100))
                                    spacing: Math.max(5, Math.min(10, main.height / 100))
                                }

                                // Кнопка активации для ветви "да"
                                Button {
                                    id: leftActivateBtn
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: Math.max(3, Math.min(5, main.width / 150))
                                    width: Math.max(20, Math.min(30, main.width / 35))
                                    height: Math.max(20, Math.min(30, main.width / 35))
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
                                        font.pixelSize: Math.max(12, Math.min(18, main.width / 40)) // Увеличенный размер
                                        font.bold: true
                                    }
                                    scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                                    Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
                                    onClicked: {
                                        if (main.activeContainer === leftContainer) {
                                            main.activeContainer = null
                                            console.log("Область 'да' деактивирована")
                                        } else {
                                            main.activeContainer = leftContainer
                                            console.log("Область 'да' активирована")
                                        }
                                    }
                                }

                                // Обработчик клика для создания блока в ветви "да"
                                TapHandler {
                                    onTapped: {
                                        if (main.activeContainer === leftContainer) {
                                            createBlock(main.selectedBlockType)
                                            console.log("Создан блок типа:", main.selectedBlockType, "в ветви 'да'")
                                        }
                                        main.activeContainer = leftContainer
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - parent.spacing) * 0.48
                                height: Math.max(120, rightContainer.childrenRect.height + Math.max(25, Math.min(40, main.height / 25)))
                                border.color: main.activeContainer === rightContainer ? "#9c27b0" : "#d32f2f"
                                border.width: 2
                                radius: 5
                                color: "transparent"

                                Column {
                                    id: rightContainer
                                    anchors.fill: parent
                                    anchors.margins: Math.max(5, Math.min(10, main.width / 100))
                                    spacing: Math.max(5, Math.min(10, main.height / 100))
                                }

                                // Кнопка активации для ветви "нет"
                                Button {
                                    id: rightActivateBtn
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: Math.max(3, Math.min(5, main.width / 150))
                                    width: Math.max(20, Math.min(30, main.width / 35))
                                    height: Math.max(20, Math.min(30, main.width / 35))
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
                                        font.pixelSize: Math.max(12, Math.min(18, main.width / 40)) // Увеличенный размер
                                        font.bold: true
                                    }
                                    scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Оставлена для этой кнопки
                                    Behavior on scale { NumberAnimation { duration: 100 } } // Оставлена для этой кнопки
                                    onClicked: {
                                        if (main.activeContainer === rightContainer) {
                                            main.activeContainer = null
                                            console.log("Область 'нет' деактивирована")
                                        } else {
                                            main.activeContainer = rightContainer
                                            console.log("Область 'нет' активирована")
                                        }
                                    }
                                }

                                // Обработчик клика для создания блока в ветви "нет"
                                TapHandler {
                                    onTapped: {
                                        if (main.activeContainer === rightContainer) {
                                            createBlock(main.selectedBlockType)
                                            console.log("Создан блок типа:", main.selectedBlockType, "в ветви 'нет'")
                                        }
                                        main.activeContainer = rightContainer
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // === Кнопка добавления блока ниже ===
            Button {
                id: addBelowButton
                // Позиционируем в левом нижнем углу блока
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 2 // Небольшое отступление
                width: Math.max(20, Math.min(30, main.width / 40))
                height: width // Квадратная кнопка
                // Используем Canvas для рисования стрелки вниз
                background: Rectangle {
                    color: "#bdbdbd" // Более светлый серый фон
                    border.color: "#9e9e9e" // Граница
                    border.width: 1
                    radius: 3 // Слегка скругленные углы
                    Canvas {
                        id: arrowCanvas
                        anchors.fill: parent
                        anchors.margins: 2
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "black"; // Цвет стрелки
                            // Рисуем стрелку вниз
                            // Простая стрелка: прямоугольник ствола + треугольник наконечника
                            var w = width;
                            var h = height;
                            var stemWidth = w * 0.2;
                            var headHeight = h * 0.3;
                            var headWidth = w * 0.4;
                            // Ствол
                            ctx.fillRect(w/2 - stemWidth/2, 0, stemWidth, h - headHeight);
                            // Наконечник
                            ctx.beginPath();
                            ctx.moveTo(w/2 - headWidth/2, h - headHeight); // Левая точка основания
                            ctx.lineTo(w/2 + headWidth/2, h - headHeight); // Правая точка основания
                            ctx.lineTo(w/2, h); // Вершина
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
                // contentItem оставляем пустым, так как рисуем на Canvas
                contentItem: Item {}
                // scale: parent.pressed ? 0.8 : (parent.hovered ? 0.9 : 1.0) // Убрано
                // Behavior on scale { NumberAnimation { duration: 100 } } // Убрано
                onClicked: {
                    console.log("Кнопка 'Добавить ниже' нажата для блока типа:", root.blockType);
                    // Вызываем функцию вставки, передавая текущий блок как опорный
                    main.insertBlockAfter(root, main.selectedBlockType);
                }
            }
            // === Конец кнопки добавления блока ниже ===
        }
    }

    function collectData() {
        function processContainer(cont) {
            var result = []
            for (var i = 0; i < cont.children.length; i++) {
                var child = cont.children[i]
                if (typeof child.getData === "function") {
                    var data = child.getData()
                    if (data.type === "усл") {
                        result.push([data.type, data.input, data.trueBranch, data.falseBranch])
                    } else if (["счетчик", "предусл", "постусл"].includes(data.type)) {
                        result.push([data.type, data.input, data.loopBody])
                    } else {
                        result.push([data.type, data.input])
                    }
                }
            }
            return result
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
        myObrabotka.myPriem(data)
        return data
    }

    // Обработчик изменения размера окна для адаптивности блоков
    onWidthChanged: {
        updateAllBlocksWidth()
    }
    onHeightChanged: {
        updateAllBlocksWidth()
    }

    function updateAllBlocksWidth() {
        function updateBlocksInContainer(container) {
            if (!container || !container.children) return;
            for (var i = 0; i < container.children.length; i++) {
                var child = container.children[i];
                if (child.hasOwnProperty("width")) {
                    child.width = container.width - Math.max(10, Math.min(20, container.width / 30));
                }
                if (child.hasOwnProperty("centerContainerPost")) {
                    updateBlocksInContainer(child.centerContainerPost);
                }
                if (child.hasOwnProperty("centerContainer")) {
                    updateBlocksInContainer(child.centerContainer);
                }
                if (child.hasOwnProperty("centerContainerCounter")) { // Новый контейнер
                    updateBlocksInContainer(child.centerContainerCounter);
                }
                if (child.hasOwnProperty("leftContainer")) {
                    updateBlocksInContainer(child.leftContainer);
                }
                if (child.hasOwnProperty("rightContainer")) {
                    updateBlocksInContainer(child.rightContainer);
                }
            }
        }
        updateBlocksInContainer(container);
    }

    // === Компонент для отображения миниатюр фигур блоков ===
    Component {
        id: miniBlockShapeItem
        Item {
            id: miniShapeItem
            property alias blockType: miniShapeCanvas.blockType

            Canvas {
                id: miniShapeCanvas
                anchors.fill: parent
                property string blockType: "действие" // Значение по умолчанию

                function getBlockColor(type) {
                    // Используем более светлые цвета для миниатюр
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
                    const w = width, h = height, cx = w/2, cy = h/2, s = Math.max(2, h * 0.2)
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
                        const hex = Math.max(3, h * 0.3)
                        ctx.moveTo(hex, 0);
                        ctx.lineTo(w-hex, 0);
                        ctx.lineTo(w, h/2)
                        ctx.lineTo(w-hex, h);
                        ctx.lineTo(hex, h);
                        ctx.lineTo(0, h/2);
                    } else if (["начало", "конец"].includes(miniShapeCanvas.blockType)) {
                        ctx.ellipse(1, 1, w-2, h-2);
                    } else {
                        // По умолчанию - прямоугольник для "действие"
                        ctx.rect(0, 0, w, h);
                    }
                    ctx.closePath();
                    ctx.fill();
                    ctx.stroke();
                    // Для "начало" и "конец" добавляем текст
                    if (["начало", "конец"].includes(miniShapeCanvas.blockType)) {
                        ctx.fillStyle = "black"; // Черный текст
                        ctx.font = "bold " + Math.max(7, h / 2) + "px Arial"; // Увеличенный размер
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText(miniShapeCanvas.blockType === "начало" ? "Н" : "К", cx, cy);
                    }
                }

                onBlockTypeChanged: requestPaint()
            }
        }
    }
    // === Конец компонента для миниатюр ===
}
