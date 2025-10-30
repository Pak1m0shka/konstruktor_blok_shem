import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import myObrabotka

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Построй алгоритм по задаче")
    Obrabotka{
        id: myObrabotka

        onNeedUserInput: {
            console.log("QML: Получен запрос на ввод")

            //вывести предложение ввода
        }

        onInputProcessed: {
            console.log("ответ вернулся") // Показываем результат
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
        spacing: 10

        RowLayout {
            spacing: 10
            RowLayout{
                Button{
                    id:vipoln
                    text:"запустить"
                    onClicked: {
                        collectData();
                    }
                }

            }
        }

        ColumnLayout{
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                border.color: "#000000"
                border.width: 3
                radius: 5
                color: "transparent"
            }
            // 🔹 Правая часть: алгоритм
            Flickable {
                id: prokrutka
                anchors.fill: parent
                clip: true
                contentHeight: container.height
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                focus: true


                TapHandler {
                    onTapped: {
                        console.log("👆 Клик: создаём ComboBox")
                        var combo = spisok.createObject(container)
                        if (combo) {
                            console.log("✅ ComboBox создан")
                        } else {
                            console.error("❌ createObject вернул null")
                        }
                    }
                }

                Column {
                    id: container
                    width: parent.width
                    spacing: 10
                }
            }
        }

        Item {

            Layout.fillWidth: true


            Layout.preferredHeight: 200
            Rectangle {
                id: outputRect
                anchors.fill: parent
                border.color: "#000000"
                border.width: 3
                radius: 5
                color: "transparent"
            }

            Text {
                id: otvet
                text: "Вывод"
                anchors.centerIn: outputRect


                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // 🔹 Левая панель: ввод и вывод
        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 10


            RowLayout{
                spacing: 10
                TextField {
                    id: vvod
                    placeholderText: "Ввод"
                    Layout.fillWidth: true
                    color:"#000000"
                    Layout.preferredHeight: 40 // Фиксированная высота
                    background: Rectangle {
                        anchors.fill: parent
                        border.color: "#000000"
                        border.width: 3
                        radius: 5

                        color: "transparent"
                    }
                }

                Button{
                    id:otvetit
                    Layout.preferredHeight: 40 // Такая же высота как у TextField

                    text:"отправить"
                    onClicked: {
                        //здесь отправляется ответ пользователя
                        myObrabotka.userInputReceived(vvod.text)
                    }
                }

            }


        }

    }

    // ✅ ПЕРЕМЕЩЕНО: Component вне RowLayout!
    Component {
        id: spisok
        Item {
            id: root
            width: parent.width
            implicitHeight: contentColumn.implicitHeight

            // 🔥 ДОБАВЛЕНА РЕКУРСИВНАЯ ФУНКЦИЯ СБОРА ДАННЫХ
            function getData() {
                var type = combo.currentText;
                var input = inputField.text.trim();

                function processContainer(container) {
                    if (!container || !container.children) return [];

                    var items = [];
                    for (var i = 0; i < container.children.length; i++) {
                        var child = container.children[i];
                        if (typeof child.getData === "function") {
                            var data = child.getData();

                            // Для условий добавляем ветки
                            if (data.type === "усл") {
                                items.push([
                                    data.type,
                                    data.input,
                                    data.trueBranch || [],
                                    data.falseBranch || []
                                ]);
                            }
                            // Для циклов
                            else if (data.type === "счетчик" || data.type === "предусл" || data.type === "постусл") {
                                items.push([
                                    data.type,
                                    data.input,
                                    data.loopBody || []
                                ]);
                            }
                            else {
                                items.push([data.type, data.input]);
                            }
                        }
                    }
                    return items;
                }

                var result = {
                    type: type,
                    input: input
                };

                // Обработка вложенных структур
                if (type === "усл") {
                    result.trueBranch = processContainer(leftContainer);
                    result.falseBranch = processContainer(rightContainer);
                }
                else if (type === "счетчик" || type === "предусл" || type === "постусл") {
                    result.loopBody = processContainer(centerContainer);
                }

                return result;
            }

            Column {
                id: contentColumn
                width: parent.width
                spacing: 5

                Row {
                    id: extraContentCklPost
                    width: parent.width
                    visible: combo.currentText === "постусл"
                    spacing: 10
                    padding: 5

                    // Левый столбец "Да"
                    ScrollView {
                        id: centerScrollPost

                        width: parent.width * 0.48
                        height: Math.max(100, centerContainerPost.height + 40)

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded


                        background: Rectangle {
                            border { color: "green"; width: 2 }
                            radius: 5
                            color: "transparent"
                        }

                        Column {
                            id: centerContainerPost
                            width: Math.max(centerScrollPost.availableWidth, implicitWidth)
                            spacing: 10

                            onChildrenChanged: Qt.callLater(() => {
                                centerScrollPost.contentWidth = centerContainerPost.childrenRect.width + 20
                            })
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                let newBlock = spisok.createObject(centerContainerPost, {
                                    width: centerContainerPost.width
                                })
                                Qt.callLater(() => {
                                    centerScrollPost.contentWidth = centerContainerPost.childrenRect.width + 20
                                })
                            }
                        }
                    }
                }

                // ▶ Фигура с фоном
                Item {
                    id: shapeItem
                    width: parent.width
                    height: getDefaultHeight()

                    function getDefaultHeight() {
                        switch (combo.currentText) {
                            case "предусл": return 90;
                            case "постусл": return 90;
                            case "усл": return 90;
                            case "счетчик": return 70;
                            default: return 50;
                        }
                    }

                    readonly property int skew: 30
                    property string type: combo.currentText

                    // Фон-фигура (теперь видимый)
                    Canvas {
                        id: background
                        anchors.fill: parent
                        antialiasing: true
                        z: -1 // Отправляем на задний план

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const w = width;
                            const h = height;
                            const s = root.skew;
                            const cx = w/2;
                            const cy = h/2;
                            const radius = h/2;

                            ctx.beginPath();

                            if (type === "действие") {
                                ctx.rect(0, 0, w, h);
                            }
                            else if (["предусл", "постусл", "усл"].includes(type)) {
                                // Ромб
                                ctx.moveTo(cx, 0);
                                ctx.lineTo(w, cy);
                                ctx.lineTo(cx, h);
                                ctx.lineTo(0, cy);
                            }
                            else if (type === "счетчик") {
                                // Капсула
                                ctx.moveTo(radius, 0);
                                ctx.arcTo(w, 0, w, h, radius);
                                ctx.arcTo(w, h, 0, h, radius);
                                ctx.arcTo(0, h, 0, 0, radius);
                                ctx.arcTo(0, 0, w, 0, radius);
                            }
                            else {
                                // Параллелограмм
                                ctx.moveTo(s, 0);
                                ctx.lineTo(w, 0);
                                ctx.lineTo(w-s, h);
                                ctx.lineTo(0, h);
                            }

                            ctx.closePath();
                            ctx.fillStyle = "#88ccee";
                            ctx.fill();
                            ctx.strokeStyle = "black";
                            ctx.lineWidth = 2;
                            ctx.stroke();
                        }
                    }

                    // ▶ Прокручиваемое содержимое фигуры
                    Flickable {
                        id: shapeFlickable
                        anchors.fill: parent
                        anchors.margins: 5
                        contentWidth: contentItem.width
                        contentHeight: contentItem.height
                        clip: true
                        interactive: contentWidth > width

                        RowLayout {
                            id: contentItem
                            width: Math.max(shapeFlickable.width, combo.width + inputField.width + 30)
                            height: shapeItem.height - 10
                            spacing: 10

                            ComboBox {
                                id: combo
                                Layout.preferredWidth: 130
                                model: ["ввод", "вывод", "действие", "счетчик", "предусл", "постусл", "усл", "конец цикл"]
                                onCurrentTextChanged: {
                                    shapeItem.type = currentText;
                                    background.requestPaint();
                                    shapeItem.height = shapeItem.getDefaultHeight();
                                }
                            }

                            TextField {
                                id: inputField
                                placeholderText: "Введите данные..."
                                Layout.fillWidth: true
                                Layout.minimumWidth: 20
                                selectByMouse: true
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: root.destroy()
                    }
                }


                Row {
                    id: extraContentCkl
                    width: parent.width
                    visible: combo.currentText === "предусл" || combo.currentText === "счетчик"
                    spacing: 10
                    padding: 5

                    // Левый столбец "Да"
                    ScrollView {
                        id: centerScroll

                        width: parent.width * 0.48
                        height: Math.max(100, centerContainer.height + 40)

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded


                        background: Rectangle {
                            border { color: "green"; width: 2 }
                            radius: 5
                            color: "transparent"
                        }

                        Column {
                            id: centerContainer
                            width: Math.max(centerScroll.availableWidth, implicitWidth)
                            spacing: 10

                            onChildrenChanged: Qt.callLater(() => {
                                centerScroll.contentWidth = centerContainer.childrenRect.width + 20
                            })
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                let newBlock = spisok.createObject(centerContainer, {
                                    width: centerContainer.width
                                })
                                Qt.callLater(() => {
                                    centerScroll.contentWidth = centerContainer.childrenRect.width + 20
                                })
                            }
                        }
                    }
                }

                // ▼ Дополнительные колонки (условия)
                Row {
                    id: extraContent
                    width: parent.width
                    visible: combo.currentText === "усл"
                    spacing: 10
                    padding: 5

                    // Левый столбец "Да"
                    ScrollView {
                        id: leftScroll

                        width: parent.width * 0.48
                        height: Math.max(100, leftContainer.height + 40)

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded


                        background: Rectangle {
                            border { color: "green"; width: 2 }
                            radius: 5
                            color: "transparent"
                        }

                        Column {
                            id: leftContainer
                            width: Math.max(leftScroll.availableWidth, implicitWidth)
                            spacing: 10

                            onChildrenChanged: Qt.callLater(() => {
                                leftScroll.contentWidth = leftContainer.childrenRect.width + 20
                            })
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                let newBlock = spisok.createObject(leftContainer, {
                                    width: leftContainer.width
                                })
                                Qt.callLater(() => {
                                    leftScroll.contentWidth = leftContainer.childrenRect.width + 20
                                })
                            }
                        }
                    }

                    // Правый столбец "Нет" (аналогично)
                    ScrollView {
                        id: rightScroll
                        width: parent.width * 0.48
                        height: Math.max(100, rightContainer.height + 20)

                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        contentWidth: rightContainer.implicitWidth + 20

                        background: Rectangle {
                            border { color: "red"; width: 2 }
                            radius: 5
                            color: "transparent"
                        }

                        Column {
                            id: rightContainer
                            width: Math.max(rightScroll.availableWidth, implicitWidth)
                            spacing: 10

                            onChildrenChanged: Qt.callLater(() => {
                                rightScroll.contentWidth = rightContainer.childrenRect.width + 20
                            })
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: {
                                let newBlock = spisok.createObject(rightContainer, {
                                    width: rightContainer.width
                                })
                                Qt.callLater(() => {
                                    rightScroll.contentWidth = rightContainer.childrenRect.width + 20
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // 🔥 ИСПРАВЛЕННАЯ ФУНКЦИЯ СБОРА ДАННЫХ
    function collectData() {
        var data = [];

        function processContainer(container) {
            var result = [];
            for (var i = 0; i < container.children.length; i++) {
                var child = container.children[i];
                if (typeof child.getData === "function") {
                    var itemData = child.getData();

                    // Для условий передаем все ветки
                    if (itemData.type === "усл") {
                        result.push([
                            itemData.type,
                            itemData.input,
                            itemData.trueBranch || [],
                            itemData.falseBranch || []
                        ]);
                    }
                    // Для циклов
                    else if (itemData.type === "счетчик" || itemData.type === "предусл" || itemData.type === "постусл") {
                        result.push([
                            itemData.type,
                            itemData.input,
                            itemData.loopBody || []
                        ]);
                    }
                    else {
                        result.push([itemData.type, itemData.input]);
                    }
                }
            }
            return result;
        }

        // Обработка основного контейнера
        data = processContainer(container);

        console.log("📤 Структура алгоритма:");
        for (var i = 0; i < data.length; i++) {
            var type = data[i][0];
            var input = data[i][1];
            console.log(`  [${type}] ${input}`);

            if (type === "усл") {
                console.log("    True ветка:", data[i][2]);
                console.log("    False ветка:", data[i][3]);
            }
            else if (type === "счетчик" || type === "предусл" || type === "постусл") {
                console.log("    Тело цикла:", data[i][2]);
            }
        }

        // Подготовка данных для C++
        var variantList = [];
        for (var j = 0; j < data.length; j++) {
            variantList.push(data[j]);
        }
        myObrabotka.myPriem(variantList);

        return data;
    }
}
