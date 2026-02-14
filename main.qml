import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import Qt.labs.platform 1.1
import myObrabotka

Window {
    id: main
    width: initialSettings.windowWidth !== undefined ? initialSettings.windowWidth : 1000
    height: initialSettings.windowHeight !== undefined ? initialSettings.windowHeight : 700
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: obrabotka.currentFilePath ? obrabotka.currentFilePath : qsTr("Построй алгоритм по задаче")

    Obrabotka {
        id: obrabotka
    }

    property var allBlocks: []

    // Стандартные темные цвета (для сброса)
    property color defaultBackgroundColor: "#121212"
    property color defaultPanelColor: "#1e1e1e"
    property color defaultTextColor: "#e0e0e0"
    property color defaultBorderColor: "#424242"
    property color defaultButtonColor: "#424242"
    property color defaultHoverColor: "#616161"
    property color defaultPressedColor: "#757575"
    property color defaultDebugTableColor: "#2d2d2d"
    property color defaultDebugTableBorderColor: "#9c27b0"
    property color defaultTranslucentColor: "#80000000"

    // Цвета кнопок спавна блоков (сделаны темнее для лучшей читаемости текста)
    property color defaultInputColor: "#7b1fa2"  // Темно-фиолетовый
    property color defaultOutputColor: "#00695c"  // Темно-бирюзовый
    property color defaultActionColor: "#1565c0"  // Темно-синий
    property color defaultCounterColor: "#c2185b"  // Темно-розовый
    property color defaultPrecondColor: "#ef6c00"  // Темно-оранжевый
    property color defaultPostcondColor: "#6a1b9a"  // Темно-фиолетовый
    property color defaultCondColor: "#2e7d32"  // Темно-зеленый
    property color defaultStartColor: "#1565c0"  // Темно-синий
    property color defaultEndColor: "#ff8f00"  // Темно-желтый

    // Текущие цвета (могут меняться пользователем)
    property color backgroundColor: defaultBackgroundColor
    property color panelColor: defaultPanelColor
    property color textColor: defaultTextColor
    property color borderColor: defaultBorderColor
    property color buttonColor: defaultButtonColor
    property color hoverColor: defaultHoverColor
    property color pressedColor: defaultPressedColor
    property color debugTableColor: defaultDebugTableColor
    property color debugTableBorderColor: defaultDebugTableBorderColor
    property color translucentColor: defaultTranslucentColor

    property color inputColor: defaultInputColor
    property color outputColor: defaultOutputColor
    property color actionColor: defaultActionColor
    property color counterColor: defaultCounterColor
    property color precondColor: defaultPrecondColor
    property color postcondColor: defaultPostcondColor
    property color condColor: defaultCondColor
    property color startColor: defaultStartColor
    property color endColor: defaultEndColor

    // Для сохранения темы
    property var savedTheme: null
    property real buttonsZoomLevel: 1.0
    property real blocksZoomLevel: 1.0
    property string currentThemeId: "dark" // New property to track current theme
    property real blockScale: 1.0

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
    property var errorBlockIds: []
    property var blockLayoutData: []
    property var flowArrowData: []
    property var allConnections: []
    property var arrowComponents: []

    function updateFlowArrows() {
        main.flowArrowData = [];
        main.allConnections = [];

        // Удаляем все существующие стрелки
        for (var i = 0; i < arrowComponents.length; i++) {
            if (arrowComponents[i]) {
                arrowComponents[i].destroy();
            }
        }
        arrowComponents = [];

        var allBlocks = collectAllBlocks();

        function findBlockById(id) {
            for (var i = 0; i < allBlocks.length; i++) {
                if (allBlocks[i].uniqueId === id) return allBlocks[i];
            }
            return null;
        }

        function processBlockConnections(block) {
            var connections = [];

            if (block.blockType === "усл") {
                var leftContainer = block.leftContainer;
                var rightContainer = block.rightContainer;

                if (leftContainer && leftContainer.children.length > 0) {
                    connections.push({
                        from: block.uniqueId,
                        to: leftContainer.children[0].uniqueId,
                        type: "yes",
                        branch: "left"
                    });

                    // Добавляем соединение от последнего блока в левой ветке к следующему блоку после условия
                    var lastInLeft = leftContainer.children[leftContainer.children.length - 1];
                    if (lastInLeft && block.parent) {
                        // Находим индекс блока условия в родительском контейнере
                        var parentChildren = block.parent.children;
                        var conditionIndex = -1;
                        for (var i = 0; i < parentChildren.length; i++) {
                            if (parentChildren[i] === block) {
                                conditionIndex = i;
                                break;
                            }
                        }
                        // Находим следующий блок после условия
                        if (conditionIndex !== -1 && conditionIndex + 1 < parentChildren.length) {
                            var nextBlock = parentChildren[conditionIndex + 1];
                            if (nextBlock && nextBlock.uniqueId !== undefined) {
                                connections.push({
                                    from: lastInLeft.uniqueId,
                                    to: nextBlock.uniqueId,
                                    type: "sequential"
                                });
                            }
                        }
                    }
                }

                if (rightContainer && rightContainer.children.length > 0) {
                    connections.push({
                        from: block.uniqueId,
                        to: rightContainer.children[0].uniqueId,
                        type: "no",
                        branch: "right"
                    });

                    // Добавляем соединение от последнего блока в правой ветке к следующему блоку после условия
                    var lastInRight = rightContainer.children[rightContainer.children.length - 1];
                    if (lastInRight && block.parent) {
                        var parentChildren = block.parent.children;
                        var conditionIndex = -1;
                        for (var i = 0; i < parentChildren.length; i++) {
                            if (parentChildren[i] === block) {
                                conditionIndex = i;
                                break;
                            }
                        }
                        if (conditionIndex !== -1 && conditionIndex + 1 < parentChildren.length) {
                            var nextBlock = parentChildren[conditionIndex + 1];
                            if (nextBlock && nextBlock.uniqueId !== undefined) {
                                connections.push({
                                    from: lastInRight.uniqueId,
                                    to: nextBlock.uniqueId,
                                    type: "sequential"
                                });
                            }
                        }
                    }
                }
            }
            else if (block.blockType === "счетчик") {
                var centerContainerCounter = block.centerContainerCounter;
                if (centerContainerCounter && centerContainerCounter.children.length > 0) {
                    connections.push({
                        from: block.uniqueId,
                        to: centerContainerCounter.children[0].uniqueId,
                        type: "loop",
                        branch: "center"
                    });

                    var lastInCounter = centerContainerCounter.children[centerContainerCounter.children.length - 1];
                    if (lastInCounter) {
                        connections.push({
                            from: lastInCounter.uniqueId,
                            to: block.uniqueId,
                            type: "back_loop"
                        });
                    }
                }
            }
            else if (block.blockType === "предусл") {
                var centerContainer = block.centerContainer;
                if (centerContainer && centerContainer.children.length > 0) {
                    connections.push({
                        from: block.uniqueId,
                        to: centerContainer.children[0].uniqueId,
                        type: "loop",
                        branch: "center"
                    });

                    var lastInLoop = centerContainer.children[centerContainer.children.length - 1];
                    if (lastInLoop) {
                        connections.push({
                            from: lastInLoop.uniqueId,
                            to: block.uniqueId,
                            type: "back_loop"
                        });
                    }
                }
            }
            else if (block.blockType === "постусл") {
                var centerContainerPost = block.centerContainerPost;
                if (centerContainerPost && centerContainerPost.children.length > 0) {
                    connections.push({
                        from: block.uniqueId,
                        to: centerContainerPost.children[0].uniqueId,
                        type: "loop",
                        branch: "center"
                    });

                    var lastInLoop = centerContainerPost.children[centerContainerPost.children.length - 1];
                    if (lastInLoop) {
                        connections.push({
                            from: lastInLoop.uniqueId,
                            to: block.uniqueId,
                            type: "back_loop"
                        });
                    }
                }
            }

            return connections;
        }

        for (var i = 0; i < allBlocks.length; i++) {
            var block = allBlocks[i];
            var blockConnections = processBlockConnections(block);
            main.allConnections = main.allConnections.concat(blockConnections);
        }

        // Добавляем последовательные соединения между блоками в основном контейнере
        for (var i = 0; i < allBlocks.length - 1; i++) {
            var currentBlock = allBlocks[i];
            var nextBlock = allBlocks[i + 1];

            // Пропускаем условные блоки, так как у них свои связи
            if (currentBlock.blockType === "усл") {
                continue;
            }

            // Пропускаем, если следующий блок уже соединен (например, в ветке условия)
            var alreadyConnected = false;
            for (var j = 0; j < main.allConnections.length; j++) {
                var conn = main.allConnections[j];
                if ((conn.from === currentBlock.uniqueId && conn.to === nextBlock.uniqueId) ||
                    (conn.from === nextBlock.uniqueId && conn.to === currentBlock.uniqueId)) {
                    alreadyConnected = true;
                    break;
                }
            }

            if (!alreadyConnected && currentBlock.parent === container && nextBlock.parent === container) {
                main.allConnections.push({
                    from: currentBlock.uniqueId,
                    to: nextBlock.uniqueId,
                    type: "sequential"
                });
            }
        }

        updateArrowVisuals();
    }

    function updateArrowVisuals() {
        var allBlocks = collectAllBlocks();
        var blockMap = {};
        for (var i = 0; i < allBlocks.length; i++) {
            var block = allBlocks[i];
            blockMap[block.uniqueId] = block;
        }

        function getBlockCenter(block) {
            var point = block.mapToItem(prokrutka, block.width / 2, block.height / 2);
            return { x: point.x, y: point.y };
        }

        function getBlockExitPoint(block) {
            if (block.blockType === "усл") {
                var point = block.mapToItem(prokrutka, block.width / 2, block.height);
                return { x: point.x, y: point.y };
            } else if (block.blockType === "счетчик" || block.blockType === "предусл" || block.blockType === "постусл") {
                var point = block.mapToItem(prokrutka, block.width / 2, block.height);
                return { x: point.x, y: point.y };
            } else {
                var point = block.mapToItem(prokrutka, block.width / 2, block.height);
                return { x: point.x, y: point.y };
            }
        }

        function getBlockEntryPoint(block) {
            var point = block.mapToItem(prokrutka, block.width / 2, 0);
            return { x: point.x, y: point.y };
        }

        for (var i = 0; i < main.allConnections.length; i++) {
            var conn = main.allConnections[i];
            var fromBlock = blockMap[conn.from];
            var toBlock = blockMap[conn.to];

            if (!fromBlock || !toBlock) continue;

            var startPoint = getBlockExitPoint(fromBlock);
            var endPoint = getBlockEntryPoint(toBlock);

            if (conn.type === "yes" || conn.type === "no") {
                // Для условий рисуем стрелки из боков ромба
                if (conn.branch === "left") {
                    startPoint = fromBlock.mapToItem(prokrutka, 0, fromBlock.height / 2);
                } else if (conn.branch === "right") {
                    startPoint = fromBlock.mapToItem(prokrutka, fromBlock.width, fromBlock.height / 2);
                }

                var container = conn.branch === "left" ? fromBlock.leftContainer : fromBlock.rightContainer;
                if (container && container.children.length > 0) {
                    endPoint = container.children[0].mapToItem(prokrutka, container.children[0].width / 2, 0);
                }

                // Создаем кривую стрелку для условий
                var middlePoint = {
                    x: (startPoint.x + endPoint.x) / 2,
                    y: (startPoint.y + endPoint.y) / 2
                };

                // Смещаем контрольную точку для красивого изгиба
                if (conn.branch === "left") {
                    middlePoint.x = startPoint.x - 50;
                    middlePoint.y = startPoint.y + 50;
                } else {
                    middlePoint.x = startPoint.x + 50;
                    middlePoint.y = startPoint.y + 50;
                }

                createCurvedArrow(startPoint, middlePoint, endPoint, conn.type === "yes" ? "#4CAF50" : "#F44336");

            } else if (conn.type === "back_loop") {
                // Обратная связь для циклов
                startPoint = getBlockExitPoint(fromBlock);
                endPoint = toBlock.mapToItem(prokrutka, toBlock.width / 2, 0);

                var middlePoint = {
                    x: (startPoint.x + endPoint.x) / 2,
                    y: Math.min(startPoint.y, endPoint.y) - 100
                };

                createCurvedArrow(startPoint, middlePoint, endPoint, "#FF9800");

            } else if (conn.type === "loop") {
                // Прямая связь от цикла к телу
                startPoint = getBlockExitPoint(fromBlock);
                endPoint = toBlock.mapToItem(prokrutka, toBlock.width / 2, 0);

                createStraightArrow(startPoint, endPoint, "#FFFFFF");

            } else if (conn.type === "sequential") {
                // Последовательная связь
                createStraightArrow(startPoint, endPoint, "#FFFFFF");
            }
        }
    }

    function createStraightArrow(startPoint, endPoint, color) {
        var arrowComponent = Qt.createComponent("Arrow.qml");
        if (arrowComponent.status === Component.Ready) {
            var arrow = arrowComponent.createObject(prokrutka, {
                startX: startPoint.x,
                startY: startPoint.y,
                endX: endPoint.x,
                endY: endPoint.y,
                arrowColor: color,
                arrowType: "straight"
            });
            if (arrow) arrowComponents.push(arrow);
        }
    }

    function createCurvedArrow(startPoint, controlPoint, endPoint, color) {
        var arrowComponent = Qt.createComponent("Arrow.qml");
        if (arrowComponent.status === Component.Ready) {
            var arrow = arrowComponent.createObject(prokrutka, {
                startX: startPoint.x,
                startY: startPoint.y,
                endX: endPoint.x,
                endY: endPoint.y,
                controlX1: controlPoint.x,
                controlY1: controlPoint.y,
                controlX2: controlPoint.x,
                controlY2: controlPoint.y,
                arrowColor: color,
                arrowType: "curved"
            });
            if (arrow) arrowComponents.push(arrow);
        }
    }

    // Функция для сбора всех блоков в порядке обхода
    function collectAllBlocks() {
        var blocks = []
        main.blockLayoutData = []

        function traverseContainer(container) {
            if (!container || !container.children) return

            for (var i = 0; i < container.children.length; i++) {
                var child = container.children[i]
                if (child && child.hasOwnProperty("blockType") && child.uniqueId !== -1) {
                    blocks.push(child)
                    var mappedRect = child.mapToItem(prokrutka, 0, 0, child.width, child.height);
                    main.blockLayoutData.push({
                        id: child.uniqueId,
                        type: child.blockType,
                        rect: mappedRect,
                        blockObject: child
                    });

                    if (child.blockType === "усл") {
                        if (child.leftContainer) traverseContainer(child.leftContainer)
                        if (child.rightContainer) traverseContainer(child.rightContainer)
                    }
                    else if (child.blockType === "счетчик" && child.centerContainerCounter) {
                        traverseContainer(child.centerContainerCounter)
                    }
                    else if (child.blockType === "предусл" && child.centerContainer) {
                        traverseContainer(child.centerContainer)
                    }
                    else if (child.blockType === "постусл" && child.centerContainerPost) {
                        traverseContainer(child.centerContainerPost)
                    }
                }
            }
        }

        traverseContainer(container)
        return blocks
    }

    function saveSettings() {
        var settings = {
            "currentThemeId": currentThemeId, // Save current theme ID
            "backgroundColor": backgroundColor,
            "panelColor": panelColor,
            "textColor": textColor,
            "borderColor": borderColor,
            "buttonColor": buttonColor,
            "hoverColor": hoverColor,
            "pressedColor": pressedColor,
            "inputColor": inputColor,
            "outputColor": outputColor,
            "actionColor": actionColor,
            "counterColor": counterColor,
            "precondColor": precondColor,
            "postcondColor": postcondColor,
            "condColor": condColor,
            "startColor": startColor,
            "endColor": endColor,
            "debugTableColor": debugTableColor,
            "debugTableBorderColor": debugTableBorderColor,
            "translucentColor": translucentColor,
            "buttonsZoomLevel": buttonsZoomLevel,
            "blocksZoomLevel": blocksZoomLevel,
            "windowWidth": main.width,
            "windowHeight": main.height
        }
        obrabotka.saveSettings(settings);
    }

    // Функция для применения загруженных настроек темы
    function applyThemeSettings() {
        if (Object.keys(initialSettings).length > 0 && initialSettings.currentThemeId !== undefined) {
            // Call the appropriate theme function based on loaded currentThemeId
            switch (initialSettings.currentThemeId) {
                case "dark":
                    resetToDarkTheme();
                    break;
                case "light":
                    resetToLightTheme();
                    break;
                case "pure_white":
                    setPureWhiteTheme();
                    break;
                case "ant":
                    setAntLightTheme();
                    break;
                case "blue":
                    setBlueTheme();
                    break;
                case "green":
                    setGreenTheme();
                    break;
                case "purple":
                    setPurpleTheme();
                    break;
                case "orange":
                    setOrangeTheme();
                    break;
                case "purple_mist":
                    setPurpleMistTheme();
                    break;
                default:
                    resetToDarkTheme(); // Fallback to dark if unknown theme
                    break;
            }

            // Apply zoom levels (these are still individual)
            if (initialSettings.buttonsZoomLevel !== undefined) buttonsZoomLevel = initialSettings.buttonsZoomLevel;
            if (initialSettings.blocksZoomLevel !== undefined) blocksZoomLevel = initialSettings.blocksZoomLevel;
        } else {
            resetToDarkTheme(); // Apply default dark theme (which also sets currentThemeId and saves)
            buttonsZoomLevel = 1.0; // Reset zoom levels
            blocksZoomLevel = 1.0;
        }
    }

    // Устанавливаем фокус на окно для обработки клавиш
    Component.onCompleted: {
        // Apply loaded settings from C++ first
        applyThemeSettings();

        if (obrabotka.currentFilePath) {
            obrabotka.loadAlgorithmFromFile(obrabotka.currentFilePath)
        }
        main.updateFlowArrows();
    }

    // Функция сброса всех цветов к стандартным темным (улучшенная для лучшей читаемости)
    function resetToDarkTheme() {
        backgroundColor = "#121212"
        panelColor = "#1e1e1e"
        textColor = "#ffffff"  // Более яркий белый для лучшей читаемости
        borderColor = "#424242"
        buttonColor = "#2d2d2d"  // Темнее для лучшего контраста
        hoverColor = "#4d4d4d"   // Ярче для лучшей видимости
        pressedColor = "#616161"
        inputColor = "#7b1fa2"   // Темнее и контрастнее
        outputColor = "#00695c"  // Темнее и контрастнее
        actionColor = "#1565c0"  // Темнее и контрастнее
        counterColor = "#c2185b" // Темнее и контрастнее
        precondColor = "#ef6c00" // Темнее и контрастнее
        postcondColor = "#6a1b9a" // Темнее и контрастнее
        condColor = "#2e7d32"    // Темнее и контрастнее
        startColor = "#1565c0"   // Темнее и контрастнее
        endColor = "#ff8f00"     // Темнее и контрастнее
        debugTableColor = "#252525"
        debugTableBorderColor = "#9c27b0"
        translucentColor = "#80000000"
        currentThemeId = "dark" // Set current theme ID
        saveSettings()
    }

    // Функция установки светлой темы (улучшенная расцветка)
    function resetToLightTheme() {
        backgroundColor = "#f5f7fa"
        panelColor = "#ffffff"
        textColor = "#1f2937"
        borderColor = "#8c8c8c"  // Сделали темнее
        buttonColor = "#e5e7eb"
        hoverColor = "#d1d5db"
        pressedColor = "#9ca3af"
        inputColor = "#8b5cf6"
        outputColor = "#10b981"
        actionColor = "#3b82f6"
        counterColor = "#ef4444"
        precondColor = "#f59e0b"
        postcondColor = "#8b5cf6"
        condColor = "#10b981"
        startColor = "#3b82f6"
        endColor = "#f59e0b"
        debugTableColor = "#ffffff"
        debugTableBorderColor = "#7c3aed"
        translucentColor = "#80000000"
        currentThemeId = "light" // Set current theme ID
        saveSettings()
    }

    // Новая белая тема "Pure White"
    function setPureWhiteTheme() {
        backgroundColor = "#ffffff"
        panelColor = "#f8f9fa"
        textColor = "#212529"
        borderColor = "#8c8c8c"  // Сделали темнее
        buttonColor = "#e9ecef"
        hoverColor = "#ced4da"
        pressedColor = "#adb5bd"
        inputColor = "#845ef7"
        outputColor = "#20c997"
        actionColor = "#339af0"
        counterColor = "#ff6b6b"
        precondColor = "#ff922b"
        postcondColor = "#cc5de8"
        condColor = "#51cf66"
        startColor = "#339af0"
        endColor = "#ff922b"
        debugTableColor = "#f8f9fa"
        debugTableBorderColor = "#845ef7"
        translucentColor = "#80000000"
        currentThemeId = "pure_white" // Set current theme ID
        saveSettings()
    }

    // Светлая тема в стиле Ant Design (с темными бордерами)
    function setAntLightTheme() {
        backgroundColor = "#fafafa"
        panelColor = "#ffffff"
        textColor = "#262626"
        borderColor = "#a6a6a6"  // Сделали темнее
        buttonColor = "#f5f5f5"
        hoverColor = "#40a9ff"
        pressedColor = "#096dd9"
        inputColor = "#9254de"
        outputColor = "#36cfc9"
        actionColor = "#1890ff"
        counterColor = "#f5222d"
        precondColor = "#fa8c16"
        postcondColor = "#722ed1"
        condColor = "#52c41a"
        startColor = "#1890ff"
        endColor = "#fa8c16"
        debugTableColor = "#ffffff"
        debugTableBorderColor = "#1890ff"
        translucentColor = "#80000000"
        currentThemeId = "ant" // Set current theme ID
        saveSettings()
    }

    // Синяя тема
    function setBlueTheme() {
        backgroundColor = "#0d1b2a"
        panelColor = "#1b263b"
        textColor = "#ffffff"  // Яркий белый для лучшей читаемости
        borderColor = "#415a77"
        buttonColor = "#2d4159"
        hoverColor = "#546b8a"
        pressedColor = "#778da9"
        inputColor = "#48cae4"
        outputColor = "#4cc9f0"
        actionColor = "#4361ee"
        counterColor = "#f72585"
        precondColor = "#ff9e00"
        postcondColor = "#b5179e"
        condColor = "#4adc91"
        startColor = "#4361ee"
        endColor = "#7209b7"
        debugTableColor = "#1b263b"
        debugTableBorderColor = "#4361ee"
        translucentColor = "#80000000"
        currentThemeId = "blue" // Set current theme ID
        saveSettings()
    }

    // Зеленая тема
    function setGreenTheme() {
        backgroundColor = "#1a1f2b"
        panelColor = "#252a34"
        textColor = "#ffffff"  // Яркий белый для лучшей читаемости
        borderColor = "#3a506b"
        buttonColor = "#2c3648"
        hoverColor = "#4a617d"
        pressedColor = "#5c7da5"
        inputColor = "#38b000"
        outputColor = "#70e000"
        actionColor = "#007200"
        counterColor = "#ff0054"
        precondColor = "#ff7b00"
        postcondColor = "#9d4edd"
        condColor = "#38b000"
        startColor = "#007200"
        endColor = "#ff7b00"
        debugTableColor = "#252a34"
        debugTableBorderColor = "#38b000"
        translucentColor = "#80000000"
        currentThemeId = "green" // Set current theme ID
        saveSettings()
    }

    // Фиолетовая тема
    function setPurpleTheme() {
        backgroundColor = "#1a1a2e"
        panelColor = "#16213e"
        textColor = "#ffffff"  // Яркий белый для лучшей читаемости
        borderColor = "#393e46"
        buttonColor = "#2a2f38"
        hoverColor = "#51565f"
        pressedColor = "#6d6d6d"
        inputColor = "#9c27b0"
        outputColor = "#4a148c"
        actionColor = "#7b1fa2"
        counterColor = "#e91e63"
        precondColor = "#ff9800"
        postcondColor = "#ab47bc"
        condColor = "#4caf50"
        startColor = "#7b1fa2"
        endColor = "#ff9800"
        debugTableColor = "#16213e"
        debugTableBorderColor = "#9c27b0"
        translucentColor = "#80000000"
        currentThemeId = "purple" // Set current theme ID
        saveSettings()
    }

    // Оранжевая тема
    function setOrangeTheme() {
        backgroundColor = "#2d1b00"
        panelColor = "#3d2800"
        textColor = "#ffffff"  // Яркий белый для лучшей читаемости
        borderColor = "#6b4f23"
        buttonColor = "#4d3a1c"
        hoverColor = "#7a6038"
        pressedColor = "#8d6e63"
        inputColor = "#ff6f00"
        outputColor = "#ff9800"
        actionColor = "#ff5722"
        counterColor = "#d32f2f"
        precondColor = "#ffb300"
        postcondColor = "#ff8a65"
        condColor = "#388e3c"
        startColor = "#ff5722"
        endColor = "#ffb300"
        debugTableColor = "#3d2800"
        debugTableBorderColor = "#ff6f00"
        translucentColor = "#80000000"
        currentThemeId = "orange" // Set current theme ID
        saveSettings()
    }

    // Новая тема "Пурпурный туман" (темная с фиолетовыми акцентами)
    function setPurpleMistTheme() {
        backgroundColor = "#0f0b1a"
        panelColor = "#1a1529"
        textColor = "#f0e6ff"  // Светло-фиолетовый текст для лучшей читаемости
        borderColor = "#3a2c5c"
        buttonColor = "#2a1f45"
        hoverColor = "#4a3a6c"
        pressedColor = "#5a4a7c"
        inputColor = "#9d4edd"
        outputColor = "#5a189a"
        actionColor = "#7b2cbf"
        counterColor = "#ff006e"
        precondColor = "#ff9e00"
        postcondColor = "#c77dff"
        condColor = "#38b000"
        startColor = "#7b2cbf"
        endColor = "#ff9e00"
        debugTableColor = "#1a1529"
        debugTableBorderColor = "#9d4edd"
        translucentColor = "#80000000"
        currentThemeId = "purple_mist" // Set current theme ID
        saveSettings()
    }

    // Функция сохранения текущей темы
    function saveCurrentTheme() {
        savedTheme = {
            backgroundColor: backgroundColor,
            panelColor: panelColor,
            textColor: textColor,
            borderColor: borderColor,
            buttonColor: buttonColor,
            hoverColor: hoverColor,
            pressedColor: pressedColor,
            inputColor: inputColor,
            outputColor: outputColor,
            actionColor: actionColor,
            counterColor: counterColor,
            precondColor: precondColor,
            postcondColor: postcondColor,
            condColor: condColor,
            startColor: startColor,
            endColor: endColor,
            debugTableColor: debugTableColor,
            debugTableBorderColor: debugTableBorderColor,
            translucentColor: translucentColor
        }
        console.log("Тема сохранена")
    }

    // Функция загрузки сохраненной темы
    function loadSavedTheme() {
        if (savedTheme) {
            backgroundColor = savedTheme.backgroundColor
            panelColor = savedTheme.panelColor
            textColor = savedTheme.textColor
            borderColor = savedTheme.borderColor
            buttonColor = savedTheme.buttonColor
            hoverColor = savedTheme.hoverColor
            pressedColor = savedTheme.pressedColor
            inputColor = savedTheme.inputColor
            outputColor = savedTheme.outputColor
            actionColor = savedTheme.actionColor
            counterColor = savedTheme.counterColor
            precondColor = savedTheme.precondColor
            postcondColor = savedTheme.postcondColor
            condColor = savedTheme.condColor
            startColor = startColor
            endColor = endColor
            debugTableColor = debugTableColor
            debugTableBorderColor = debugTableBorderColor
            translucentColor = translucentColor
            console.log("Тема загружена из сохранения")
        } else {
            console.log("Нет сохраненной темы")
        }
    }

    // Вспомогательная функция для получения цвета блока по типу
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
        target: obrabotka
        function onNeedUserInput() {
            console.log("QML: Получен запрос на ввод")
            otvet.text = otvet.text + "\n" + "QML: Получен запрос на ввод"
        }
        function onInputProcessed(result) {
            console.log("ответ вернулся")
        }
        function onVivod(otvet_cpp) {
            console.log("ответ есть")
            console.log(otvet_cpp)
            otvet.text = otvet.text + "\n" + otvet_cpp
        }
        function onDebugging_peremennie(peremennie) {
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

        function onHighlightBlock(blockId) {
            console.log("Получен сигнал highlightBlock с ID:", blockId);
            currentDebugBlockId = blockId;
        }

        function onDebugHistoryChanged(canStepBack, canStepForward) {
            console.log("История отладки изменилась, можно шагать назад:", canStepBack, "можно шагать вперед:", canStepForward);
            main.canStepBack = canStepBack;
            main.canStepForward = canStepForward;
        }

        function onDebugFinished() {
            console.log("Отладка завершена");
            main.debugMode = false;
            variablesModel.clear();
            currentDebugBlockId = -1;
            errorBlockIds = [];
        }

        function onAlgorithmLoaded(algorithm) {
            console.log("Получен сигнал algorithmLoaded, количество блоков:", algorithm.length)
            main.debugStartBlockId = -1
            main.errorBlockIds = [];
            if (algorithm && algorithm.length > 0) {
                loadAlgorithm(algorithm, container)
                main.updateFlowArrows();
            }
        }

        function onErrorOccurred(errorMessage) {
            console.log("Ошибка:", errorMessage)
            otvet.text = otvet.text + "\n" + "Ошибка: " + errorMessage
            errorBlockIds = [];
        }
        function onFileSaved(filePath) {
            otvet.text = otvet.text + "\n" + "Файл сохранен: " + filePath
        }

        function onSyntaxErrorsOccurred(errors) {
            console.log("Получены синтаксические ошибки:", errors);
            otvet.text += "\n" + "--- Синтаксические ошибки ---\n";

            main.errorBlockIds = [];

            var newErrorBlockIds = [];
            if (errors && errors.length > 0) {
                for (var i = 0; i < errors.length; i++) {
                    var error = errors[i];
                    var message = error.message || "Неизвестная ошибка";
                    var blockId = error.blockId;
                    var errorString = "Ошибка: " + message;
                    if (blockId !== -1) {
                        errorString += " (Блок ID: " + blockId + ")";
                        newErrorBlockIds.push(blockId);
                    }
                    otvet.text += errorString + "\n";
                }
                if (main.debugMode) {
                    main.debugMode = false;
                    obrabotka.stopDebugging();
                }
            } else {
                otvet.text += "Неизвестные синтаксические ошибки (ноль ошибок).\n";
            }
            main.errorBlockIds = newErrorBlockIds;
            main.updateBlockHighlight();
        }
    }

    Connections {
        target: main
        function onBlocksZoomLevelChanged() {
            main.updateFlowArrows();
        }
        function onBlockScaleChanged() {
            main.updateFlowArrows();
        }
    }

    FileDialog {
        id: saveAsDialog
        title: "Сохранить как..."
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            var data = main.collectData(0);
            obrabotka.saveAlgorithmToFile(data, saveAsDialog.file);
            confirmWindow.close();
        }
        onRejected: {
            console.log("Сохранение файла отменено.");
            confirmWindow.close();
        }
    }

    FileDialog {
        id: newFileDialog
        title: "Создать новый алгоритм"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            var data = main.collectData(0);
            if (obrabotka.saveAlgorithmToFile(data, newFileDialog.file)) {
                obrabotka.createNewInstance(newFileDialog.file);
                Qt.quit();
            }
            confirmWindow.close();
        }
        onRejected: {
            console.log("Создание нового файла отменено.");
            confirmWindow.close();
        }
    }

    FileDialog {
        id: openDialog
        title: "Открыть алгоритм"
        fileMode: FileDialog.OpenFile
        nameFilters: [ "JSON files (*.json)", "All files (*)" ]
        onAccepted: {
            obrabotka.loadAlgorithmFromFile(openDialog.file);
            confirmWindow.close();
        }
        onRejected: {
            console.log("Открытие файла отменено.");
            confirmWindow.close();
        }
    }

    property string userInputResult: ""

    // Window для подтверждения операций
    Window {
        id: confirmWindow
        width: 300
        height: 150
        modality: Qt.ApplicationModal
        flags: Qt.Dialog
        visible: false
        title: "Подтверждение"
        color: panelColor

        property string operation: ""
        property var callback: null

        function openWindow() {
            confirmWindow.x = main.x + (main.width - confirmWindow.width) / 2
            confirmWindow.y = main.y + (main.height - confirmWindow.height) / 2
            confirmWindow.visible = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                id: popupTitle
                width: parent.width
                text: {
                    if (confirmWindow.operation === "save") return "Сохранить текущую тему?"
                    else if (confirmWindow.operation === "load") return "Загрузить сохраненную тему?"
                    else return "Подтвердите действие"
                }
                color: textColor
                font.pixelSize: 16
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "Да"
                    width: 100
                    height: 40

                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        if (confirmWindow.callback) {
                            confirmWindow.callback()
                        }
                        confirmWindow.close()
                    }
                }

                Button {
                    text: "Нет"
                    width: 100
                    height: 40

                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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

                    onClicked: confirmWindow.close()
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // === Единая панель кнопок (запуск, отладка, настройки и спавн блоков) ===
        Item {
            id: buttonsPanel
            Layout.fillWidth: true
            Layout.preferredHeight: 60 * buttonsZoomLevel

            Flickable {
                id: buttonsFlickable
                anchors.fill: parent
                contentWidth: buttonsRow.width
                contentHeight: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    acceptedModifiers: Qt.ControlModifier
                    onWheel: function(event) {
                        var newZoom = buttonsZoomLevel + event.angleDelta.y * 0.001
                        if (newZoom >= 0.5 && newZoom <= 2.0) {
                            buttonsZoomLevel = newZoom
                        }
                    }
                }

                ScrollBar.horizontal: ScrollBar {
                    id: scrollBar
                    policy: ScrollBar.AsNeeded
                    visible: buttonsFlickable.contentWidth > buttonsFlickable.width
                }

                Row {
                    id: buttonsRow
                    height: parent.height
                    spacing: 5 * buttonsZoomLevel
                    transform: Scale {
                        xScale: buttonsZoomLevel;
                        yScale: buttonsZoomLevel;
                        origin.x: 0;
                        origin.y: buttonsRow.height/2
                    }

                    // Кнопка запуска
                    Button {
                        id: runButton
                        text: "Запуск"
                        hoverEnabled: true
                        onClicked: collectData(1)
                        height: parent.height
                        width: 150 * buttonsZoomLevel

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
                            font.pixelSize: 16 * buttonsZoomLevel
                            font.bold: true
                        }
                    }

                    // Кнопка отладки
                    Button {
                        id: debugButton
                        text: main.debugMode ? "Закончить отладку" : "Отладка"
                        hoverEnabled: true
                        height: parent.height
                        width: 180 * buttonsZoomLevel

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
                            font.pixelSize: 16 * buttonsZoomLevel
                            font.bold: true
                        }

                        onClicked: {
                            if (main.debugMode) {
                                console.log("Нажата кнопка 'Закончить отладку'");
                                obrabotka.stopDebugging();
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
                        height: parent.height
                        width: 150 * buttonsZoomLevel

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
                            font.pixelSize: 16 * buttonsZoomLevel
                            font.bold: true
                        }

                        onClicked: {
                            settingsWindow.openWindow();
                        }
                    }

                    // Разделитель
                    Rectangle {
                        height: parent.height
                        width: 2
                        color: borderColor

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    // Выбор типа блока
                    ComboBox {
                        id: blockTypeSelector
                        enabled: !main.debugMode
                        width: 250 * buttonsZoomLevel
                        height: parent.height
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
                        contentItem: Item {
                            anchors.fill: parent
                            Row {
                                anchors.centerIn: parent
                                spacing: 5 * buttonsZoomLevel
                                Loader {
                                    id: selectedBlockMiniShapeLoader
                                    width: 25 * buttonsZoomLevel
                                    height: 25 * buttonsZoomLevel
                                    sourceComponent: miniBlockShapeItem
                                    onLoaded: {
                                        item.blockType = main.selectedBlockType;
                                        item.scale = buttonsZoomLevel;
                                    }
                                    Connections {
                                        target: main
                                        function onSelectedBlockTypeChanged() {
                                            if (selectedBlockMiniShapeLoader.item) {
                                                selectedBlockMiniShapeLoader.item.blockType = main.selectedBlockType;
                                            }
                                        }
                                        function onButtonsZoomLevelChanged() {
                                            if (selectedBlockMiniShapeLoader.item) {
                                                selectedBlockMiniShapeLoader.item.scale = buttonsZoomLevel;
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
                                    font.pixelSize: 18 * buttonsZoomLevel
                                    font.bold: true
                                }
                            }
                        }
                        delegate: ItemDelegate {
                            id: delegateItem
                            width: parent.width
                            height: 45 * buttonsZoomLevel
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
                                anchors.centerIn: parent
                                spacing: 5 * buttonsZoomLevel
                                Loader {
                                    width: 30 * buttonsZoomLevel
                                    height: 30 * buttonsZoomLevel
                                    sourceComponent: miniBlockShapeItem
                                    onLoaded: {
                                        item.blockType = model.type;
                                        item.scale = buttonsZoomLevel;
                                    }
                                }
                                Text {
                                    text: model.displayName
                                    color: textColor
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 18 * buttonsZoomLevel
                                }
                            }
                        }
                        indicator: Canvas {
                            x: parent.width - width - 10
                            y: parent.height / 2 - height / 2
                            width: 12 * buttonsZoomLevel
                            height: 8 * buttonsZoomLevel
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
                        height: parent.height
                        width: 100 * buttonsZoomLevel

                        background: Rectangle {
                            id: inputBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Ввод"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { inputCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: outputBtn
                        text: "Вывод"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("вывод")
                        height: parent.height
                        width: 100 * buttonsZoomLevel

                        background: Rectangle {
                            id: outputBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Вывод"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { outputCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: actionBtn
                        text: "Действие"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("действие")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: actionBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.strokeRect(0, 0, w, h)
                                }
                            }

                            Text {
                                text: "Действие"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { actionCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: counterBtn
                        text: "Счетчик"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("счетчик")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: counterBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    var w = width, h = height
                                    var hex = h * 0.3
                                    ctx.beginPath()
                                    ctx.moveTo(hex, 0);
                                    ctx.lineTo(w-hex, 0);
                                    ctx.lineTo(w, h/2)
                                    ctx.lineTo(w-hex, h);
                                    ctx.lineTo(hex, h);
                                    ctx.lineTo(0, h/2)
                                    ctx.closePath();
                                    var fillColor = counterBtn.pressed ? Qt.darker(counterColor, 1.3) :
                                                    (counterBtn.hovered ? Qt.lighter(counterColor, 1.2) : counterColor)
                                    ctx.fillStyle = fillColor
                                    ctx.fill()
                                    ctx.strokeStyle = counterBtn.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Счетчик"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { counterCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: precondBtn
                        text: "Предусл"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("предусл")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: precondBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Предусл"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { precondCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: postcondBtn
                        text: "Постусл"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("постусл")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: postcondBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Постусл"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { postcondCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: condBtn
                        text: "Усл"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("усл")
                        height: parent.height
                        width: 100 * buttonsZoomLevel

                        background: Rectangle {
                            id: condBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                }
                            }

                            Text {
                                text: "Усл"
                                anchors.centerIn: parent
                                color: textColor
                                font.bold: true
                                font.pixelSize: 18 * buttonsZoomLevel
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
                            function onButtonsZoomLevelChanged() { condCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: startBtn
                        text: "Начало"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("начало")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: startBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                    ctx.fillStyle = textColor
                                    ctx.font = "bold " + (20 * buttonsZoomLevel) + "px Arial"
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
                            function onButtonsZoomLevelChanged() { startCanvas.requestPaint() }
                        }
                    }

                    Button {
                        id: endBtn
                        text: "Конец"
                        enabled: !main.debugMode
                        hoverEnabled: true
                        onClicked: createBlock("конец")
                        height: parent.height
                        width: 120 * buttonsZoomLevel

                        background: Rectangle {
                            id: endBtnBg
                            color: "transparent"
                            border.width: 0
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
                                anchors.margins: 3 * buttonsZoomLevel
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
                                    ctx.lineWidth = 2 * buttonsZoomLevel
                                    ctx.stroke()
                                    ctx.fillStyle = textColor
                                    ctx.font = "bold " + (20 * buttonsZoomLevel) + "px Arial"
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
                            function onButtonsZoomLevelChanged() { endCanvas.requestPaint() }
                        }
                    }
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
                    contentHeight: container.height * blocksZoomLevel
                    contentWidth: container.width * blocksZoomLevel
                    flickableDirection: Flickable.HorizontalAndVerticalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        acceptedModifiers: Qt.ControlModifier
                        onWheel: function(event) {
                            var newZoom = blocksZoomLevel + event.angleDelta.y * 0.001
                            if (newZoom >= 0.5 && newZoom <= 2.0) {
                                blocksZoomLevel = newZoom
                            }
                        }
                    }

                    Column {
                        id: container
                        width: Math.max(prokrutka.width / blocksZoomLevel, childrenRect.width)
                        spacing: 10 * blocksZoomLevel
                        padding: 5 * blocksZoomLevel
                        transform: Scale {
                            xScale: blocksZoomLevel
                            yScale: blocksZoomLevel
                            origin.x: 0
                            origin.y: 0
                        }
                    }

                    Button {
                        id: mainActivateBtn
                        enabled: !main.debugMode
                        hoverEnabled: true
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 5
                        width: 35 * blocksZoomLevel
                        height: 35 * blocksZoomLevel
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
                            font.pixelSize: 18 * blocksZoomLevel
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
                                main.updateFlowArrows();
                            }
                        }
                    }
                }
            }

            // === Панель отладки ===
            Rectangle {
                id: debugPanel
                height: parent.height

                states: [
                    State {
                        name: "debugActive"
                        when: main.debugMode
                        PropertyChanges { target: debugPanel; width: 350; opacity: 1; visible: true }
                    },
                    State {
                        name: "debugInactive"
                        when: !main.debugMode
                        PropertyChanges { target: debugPanel; width: 0; opacity: 0; visible: false }
                    }
                ]

                transitions: [
                    Transition {
                        from: "*"
                        to: "*"
                        NumberAnimation { properties: "width,opacity"; duration: 300; easing.type: Easing.InOutQuad }
                    }
                ]
                border.color: debugTableBorderColor
                border.width: 2
                radius: 5
                color: debugTableColor

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
                                    obrabotka.debugStepBack();
                                }
                            }
                        }

                        Button {
                            id: forwardButton
                            text: "Вперёд"
                            enabled: main.debugMode && main.canStepForward
                            hoverEnabled: true
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
                                    obrabotka.debugStep();
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
                                color: index % 2 === 0 ? Qt.lighter(debugTableColor, 1.1) : debugTableColor
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
                                color: Qt.darker(debugTableColor, 1.2)
                                border.color: borderColor
                                border.width: 1
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
                            obrabotka.stopDebugging();
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
                    color: panelColor

                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }
            }

            Button {
                id: sendButton
                text: "Отправить"
                hoverEnabled: true
                Layout.preferredHeight: 50
                Layout.preferredWidth: 150
                onClicked: obrabotka.userInputReceived(vvod.text)

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

        var colorForBlock;
        switch (type) {
            case "ввод": colorForBlock = inputColor; break;
            case "вывод": colorForBlock = outputColor; break;
            case "действие": colorForBlock = actionColor; break;
            case "счетчик": colorForBlock = counterColor; break;
            case "предусл": colorForBlock = precondColor; break;
            case "постусл": colorForBlock = postcondColor; break;
            case "усл": colorForBlock = condColor; break;
            case "начало": colorForBlock = startColor; break;
            case "конец": colorForBlock = endColor; break;
            default: colorForBlock = actionColor; break;
        }

        var newBlock = spisok.createObject(main.activeContainer, {
            "blockType": type,
            "uniqueId": main.blockIdCounter,
            "customColor": colorForBlock
        })
        main.blockIdCounter++;
        main.updateFlowArrows();
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
        main.updateFlowArrows();
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
        main.updateFlowArrows();
    }

    Component {
        id: spisok
        Item {
            id: root
            width: Math.max(childrenRect.width, 350) * blockScale
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: contentColumn.implicitHeight * blockScale
            property string blockType: "действие"
            property bool isDebugHighlighted: false
            property int uniqueId: -1
            property bool isDebugStart: main.debugStartBlockId === root.uniqueId
            property bool hovered: false
            property color customColor: "transparent"

            // Свойства для доступа к контейнерам
            property alias leftContainer: leftContainer
            property alias rightContainer: rightContainer
            property alias centerContainer: centerContainer
            property alias centerContainerCounter: centerContainerCounter
            property alias centerContainerPost: centerContainerPost

            function setTextFields(blockType, input, counterVar, counterFrom, counterTo, counterStep) {
                if (blockType === "усл" || blockType === "предусл" || blockType === "постусл") {
                    inputFieldDiamond.text = input;
                } else if (blockType === "счетчик") {
                    if (counterVar) counterVarField.text = counterVar;
                    if (counterFrom) counterFromField.text = counterFrom;
                    if (counterTo) counterToField.text = counterTo;
                    if (counterStep) counterStepField.text = counterStep;
                } else if (blockType !== "начало" && blockType !== "конец") {
                    inputField.text = input;
                }
            }

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
                        "falseBranch": processContainer(rightContainer),
                        "customColor": root.customColor
                    };
                } else if (root.blockType === "счетчик") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": counterVarField.text.trim() + " = " +
                               counterFromField.text.trim() + " to " +
                               counterToField.text.trim() + " step " +
                               counterStepField.text.trim(),
                        "loopBody": processContainer(centerContainerCounter),
                        "customColor": root.customColor
                    };
                } else if (root.blockType === "предусл") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputFieldDiamond.text.trim(),
                        "loopBody": processContainer(centerContainer),
                        "customColor": root.customColor
                    };
                } else if (root.blockType === "постусл") {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputFieldDiamond.text.trim(),
                        "loopBody": processContainer(centerContainerPost),
                        "customColor": root.customColor
                    };
                } else {
                    result = {
                        "type": root.blockType,
                        "uniqueId": root.uniqueId,
                        "input": inputField.text.trim(),
                        "customColor": root.customColor
                    };
                }
                return result;
            }

            property var _blockCanvasRef: null
            function registerBlockCanvas(canvas) {
                _blockCanvasRef = canvas;
            }

            function updateBlockColor(newColor) {
                root.customColor = newColor;
                if (root._blockCanvasRef) {
                    root._blockCanvasRef.requestPaint();
                } else {
                    console.warn("blockCanvas not registered for block ID:", root.uniqueId);
                }
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
                spacing: 0
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    id: contentColumn
                    width: Math.max(500 * blockScale, childrenRect.width) // Увеличено с 450
                    spacing: 10 * blockScale

                    // === ОБЛАСТЬ ДЛЯ ПОСТУСЛОВИЯ (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: postConditionWrapper
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? postConditionContent.height + 10 * blockScale : 0
                        visible: root.blockType === "постусл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: postConditionContent
                            width: Math.max(400 * blockScale, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10 * blockScale

                            Rectangle {
                                id: postRect
                                width: Math.max(400 * blockScale, centerContainerPost.childrenRect.width + 40 * blockScale)
                                height: Math.max(160 * blockScale, centerContainerPost.childrenRect.height + 50 * blockScale)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerPost ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 * blockScale : 2 * blockScale
                                radius: 5 * blockScale
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Column {
                                    id: centerContainerPost
                                    objectName: "centerContainerPost"
                                    width: Math.max(350 * blockScale, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10 * blockScale
                                }

                                Button {
                                    id: postActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5 * blockScale
                                    width: 35 * blockScale
                                    height: 35 * blockScale
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
                                        border.width: 1 * blockScale
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
                                        font.pixelSize: 18 * blockScale
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
                                            main.updateFlowArrows();
                                        }
                                        main.activeContainer = centerContainerPost
                                    }
                                }
                            }
                        }
                    }
                    // === ФИГУРА БЛОКА (ОСНОВНАЯ ЧАСТЬ) ===
                    Item {
                        id: shapeItem
                        width: 400 * blockScale // Увеличено с 350

                        height: getDefaultHeight() * blockScale
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            spacing: 2 * blockScale
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.left
                            anchors.rightMargin: 5 * blockScale
        
                            Button {
                                id: setDebugStartButton
                                enabled: !main.debugMode && !["начало", "конец"].includes(root.blockType)
                                width: 30 * blockScale
                                height: 30 * blockScale
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
                                    radius: 15 * blockScale
        
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
                                    font.pixelSize: 18 * blockScale
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
        
                            Button {
                                id: colorButton
                                enabled: !main.debugMode && !["начало", "конец"].includes(root.blockType)
                                width: 30 * blockScale
                                height: 30 * blockScale
                                hoverEnabled: true
        
                                background: Rectangle {
                                    id: colorButtonBg
                                    color: {
                                        if (colorButton.pressed) {
                                            var c = Qt.darker(buttonColor, 1.25);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else if (colorButton.hovered) {
                                            var c = Qt.lighter(buttonColor, 1.15);
                                            return Qt.rgba(c.r, c.g, c.b, 1);
                                        } else return buttonColor
                                    }
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 15 * blockScale
        
                                    Behavior on color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                }
        
                                contentItem: Text {
                                    text: "Ц"
                                    color: textColor
                                    font.bold: true
                                    font.pixelSize: 18 * blockScale
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
        
                                onClicked: {
                                    colorWindow.blockItem = root;
                                    colorWindow.openWindow();
                                }
                            }
                        }

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
                            border.width: 4 * blockScale
                            radius: 5 * blockScale
                            color: "transparent"
                            visible: root.isDebugHighlighted
                            z: 1
                        }

                        Canvas {
                            id: blockCanvas
                            Component.onCompleted: root.registerBlockCanvas(blockCanvas)
                            anchors.fill: parent
                            antialiasing: true
                            z: 0
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                const w = width, h = height, cx = w/2, cy = h/2, s = 20 * blockScale
                                ctx.beginPath()
                                var fillColor;
                                if (root.customColor !== "transparent") {
                                    fillColor = root.hovered ? Qt.lighter(root.customColor, 1.15) : root.customColor;
                                } else if (root.hovered) {
                                    fillColor = Qt.lighter(main.getBlockColor(root.blockType), 1.15);
                                } else {
                                    fillColor = main.getBlockColor(root.blockType);
                                }
                                ctx.fillStyle = fillColor;
                                var isErrorBlock = main.errorBlockIds.includes(root.uniqueId);
                                ctx.strokeStyle = isErrorBlock ? "red" : (root.isDebugHighlighted ? "yellow" : (root.isDebugStart ? "#FF69B4" : borderColor))
                                ctx.lineWidth = isErrorBlock ? 5 * blockScale : (root.isDebugHighlighted ? 3 * blockScale : (root.isDebugStart ? 4 * blockScale : 2 * blockScale))
                                if (["ввод", "вывод"].includes(root.blockType)) {
                                    ctx.moveTo(s, 0);
                                    ctx.lineTo(w, 0);
                                    ctx.lineTo(w-s, h);
                                    ctx.lineTo(0, h)
                                } else if (["усл", "предусл", "постусл"].includes(root.blockType)) {
                                    ctx.moveTo(cx, 5 * blockScale);
                                    ctx.lineTo(w-5 * blockScale, cy);
                                    ctx.lineTo(cx, h-5 * blockScale);
                                    ctx.lineTo(5 * blockScale, cy)
                                } else if (root.blockType === "счетчик") {
                                    const hex = 20 * blockScale
                                    ctx.moveTo(hex, 0);
                                    ctx.lineTo(w-hex, 0);
                                    ctx.lineTo(w, h/2)
                                    ctx.lineTo(w-hex, h);
                                    ctx.lineTo(hex, h);
                                    ctx.lineTo(0, h/2)
                                } else if (["начало", "конец"].includes(root.blockType)) {
                                    ctx.ellipse(5 * blockScale, 5 * blockScale, w-10 * blockScale, h-10 * blockScale)
                                } else {
                                    ctx.rect(0, 0, w, h)
                                }
                                ctx.closePath();
                                ctx.fill();
                                ctx.stroke()
                                if (["начало", "конец"].includes(root.blockType)) {
                                    ctx.fillStyle = textColor
                                    ctx.font = "bold " + (20 * blockScale) + "px Arial"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText(root.blockType === "начало" ? "Начало" : "Конец", cx, cy)
                                }
                            }
                        }

                        TextField {
                            id: inputField
                            objectName: "inputField"
                            enabled: !main.debugMode
                            anchors.centerIn: parent
                            width: parent.width - 30 * blockScale
                            visible: !["начало", "конец", "счетчик", "усл", "предусл", "постусл"].includes(root.blockType)
                            placeholderText: ({
                                "ввод": "Введите переменные для ввода...",
                                "вывод": "Введите данные для вывода...",
                                "действие": "Введите действие...",
                            })[root.blockType] || "Введите данные..."
                            color: textColor
                            placeholderTextColor: "#757575"
                            selectByMouse: true
                            font.pixelSize: 26 * blockScale
                            font.bold: true
                            hoverEnabled: true

                            background: Rectangle {
                                color: "transparent";
                                border.width: 0
                            }
                        }

                        TextField {
                            id: inputFieldDiamond
                            objectName: "inputFieldDiamond"
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
                            font.pixelSize: 26 * blockScale
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
                            spacing: 10 * blockScale
                            visible: root.blockType === "счетчик"

                            Row {
                                spacing: 10 * blockScale
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    spacing: 5 * blockScale
                                    Text {
                                        text: "Переменная:"
                                        color: textColor
                                        font.pixelSize: 18 * blockScale
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterVarField
                                        objectName: "counterVarField"
                                        enabled: !main.debugMode
                                        width: 50 * blockScale
                                        placeholderText: "i"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 20 * blockScale
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1 * blockScale
                                            radius: 4 * blockScale

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 5 * blockScale
                                    Text {
                                        text: "Шаг:"
                                        color: textColor
                                        font.pixelSize: 18 * blockScale
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterStepField
                                        objectName: "counterStepField"
                                        enabled: !main.debugMode
                                        width: 50 * blockScale
                                        placeholderText: "1"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 20 * blockScale
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1 * blockScale
                                            radius: 4 * blockScale

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 10 * blockScale
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    spacing: 5 * blockScale
                                    Text {
                                        text: "От:"
                                        color: textColor
                                        font.pixelSize: 18 * blockScale
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterFromField
                                        objectName: "counterFromField"
                                        enabled: !main.debugMode
                                        width: 50 * blockScale
                                        placeholderText: "0"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 20 * blockScale
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1 * blockScale
                                            radius: 4 * blockScale

                                            Behavior on border.color {
                                                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 5 * blockScale
                                    Text {
                                        text: "До:"
                                        color: textColor
                                        font.pixelSize: 18 * blockScale
                                        font.bold: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    TextField {
                                        id: counterToField
                                        objectName: "counterToField"
                                        enabled: !main.debugMode
                                        width: 50 * blockScale
                                        placeholderText: "10"
                                        color: textColor
                                        placeholderTextColor: "#9e9e9e"
                                        selectByMouse: true
                                        font.pixelSize: 20 * blockScale
                                        font.bold: true
                                        hoverEnabled: true

                                        background: Rectangle {
                                            color: "transparent"
                                            border.color: borderColor
                                            border.width: 1 * blockScale
                                            radius: 4 * blockScale

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
                            anchors.leftMargin: 5 * blockScale
                            spacing: 2 * blockScale

                            Button {
                                id: addAboveButton
                                enabled: !main.debugMode
                                width: 30 * blockScale
                                height: 30 * blockScale
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
                                    border.width: 1 * blockScale
                                    radius: 3 * blockScale

                                    Behavior on color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3 * blockScale
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
                                width: 30 * blockScale
                                height: 30 * blockScale
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
                                    border.width: 1 * blockScale
                                    radius: 3 * blockScale

                                    Behavior on color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Canvas {
                                        anchors.fill: parent
                                        anchors.margins: 3 * blockScale
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
                                main.updateFlowArrows();
                            }
                        }

                        TapHandler {
                            enabled: !main.debugMode
                            acceptedButtons: Qt.LeftButton
                            onDoubleTapped: {
                                console.log("Блок удалён двойным кликом. ID:", root.uniqueId);
                                root.destroy()
                                main.updateFlowArrows();
                            }
                        }
                    }

                    // === ОБЛАСТЬ ДЛЯ СЧЕТЧИКА (РАСПОЛОЖЕНА ПОД ФИГУРОЙ) ===
                    Item {
                        id: counterContainer
                        width: Math.max(parent.width, childrenRect.width)
                        height: visible ? counterContent.height + 10 * blockScale : 0
                        visible: root.blockType === "счетчик"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: counterContent
                            width: Math.max(400 * blockScale, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10 * blockScale

                            Rectangle {
                                id: counterRect
                                width: Math.max(400 * blockScale, centerContainerCounter.childrenRect.width + 40 * blockScale)
                                height: Math.max(160 * blockScale, centerContainerCounter.childrenRect.height + 50 * blockScale)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainerCounter ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 * blockScale : 2 * blockScale
                                radius: 5 * blockScale
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Column {
                                    id: centerContainerCounter
                                    objectName: "centerContainerCounter"
                                    width: Math.max(350 * blockScale, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10 * blockScale
                                }

                                Button {
                                    id: counterActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5 * blockScale
                                    width: 35 * blockScale
                                    height: 35 * blockScale
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
                                        border.width: 1 * blockScale
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
                                        font.pixelSize: 18 * blockScale
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
                                            main.updateFlowArrows();
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
                        height: visible ? cycleContentDefault.height + 10 * blockScale : 0
                        visible: root.blockType === "предусл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: cycleContentDefault
                            width: Math.max(400 * blockScale, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10 * blockScale

                            Rectangle {
                                id: cycleRect
                                width: Math.max(400 * blockScale, centerContainer.childrenRect.width + 40 * blockScale)
                                height: Math.max(160 * blockScale, centerContainer.childrenRect.height + 50 * blockScale)
                                border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === centerContainer ? "#9c27b0" : borderColor)
                                border.width: root.isDebugHighlighted ? 4 * blockScale : 2 * blockScale
                                radius: 5 * blockScale
                                color: "transparent"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on border.color {
                                    ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Column {
                                    id: centerContainer
                                    objectName: "centerContainer"
                                    width: Math.max(350 * blockScale, childrenRect.width)
                                    anchors.centerIn: parent
                                    spacing: 10 * blockScale
                                }

                                Button {
                                    id: cycleActivateBtn
                                    enabled: !main.debugMode
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 5 * blockScale
                                    width: 35 * blockScale
                                    height: 35 * blockScale
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
                                        border.width: 1 * blockScale
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
                                        font.pixelSize: 18 * blockScale
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
                                            main.updateFlowArrows();
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
                        width: conditionContent.width

                        height: visible ? conditionContent.height + 10 * blockScale : 0
                        visible: root.blockType === "усл"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Column {
                            id: conditionContent
                            width: Math.max(700 * blockScale, conditionRow.width) // Увеличено с 600
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10 * blockScale

                            Row {
                                id: conditionRow
                                width: Math.max(600 * blockScale, childrenRect.width)
                                spacing: 20 * blockScale
                                anchors.horizontalCenter: parent.horizontalCenter

                                // Левая ветка (истина)
                                Rectangle {
                                    id: leftRect
                                    width: Math.max(300 * blockScale, leftContainer.width + 40 * blockScale) // Увеличено с 280

                                    height: Math.max(160 * blockScale, leftContainer.childrenRect.height + 50 * blockScale)
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === leftContainer ? "#9c27b0" : borderColor)
                                    border.width: root.isDebugHighlighted ? 4 * blockScale : 2 * blockScale
                                    radius: 5 * blockScale
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Column {
                                        id: leftContainer
                                        objectName: "leftContainer"
                                        width: Math.max(280 * blockScale, childrenRect.width) // Увеличено с 250

                                        anchors.centerIn: parent
                                        spacing: 10 * blockScale
                                    }

                                    Button {
                                        id: leftActivateBtn
                                        enabled: !main.debugMode
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 5 * blockScale
                                        width: 35 * blockScale
                                        height: 35 * blockScale
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
                                            border.width: 1 * blockScale
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
                                            font.pixelSize: 18 * blockScale
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
                                                main.updateFlowArrows();
                                            }
                                            main.activeContainer = leftContainer
                                        }
                                    }
                                }

                                // Правая ветка (ложь)
                                Rectangle {
                                    id: rightRect
                                    width: Math.max(300 * blockScale, rightContainer.width + 40 * blockScale) // Увеличено с 280

                                    height: Math.max(160 * blockScale, rightContainer.childrenRect.height + 50 * blockScale)
                                    border.color: root.isDebugHighlighted ? "yellow" : (main.activeContainer === rightContainer ? "#9c27b0" : borderColor)
                                    border.width: root.isDebugHighlighted ? 4 * blockScale : 2 * blockScale
                                    radius: 5 * blockScale
                                    color: "transparent"

                                    Behavior on border.color {
                                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                                    }

                                    Column {
                                        id: rightContainer
                                        objectName: "rightContainer"
                                        width: Math.max(280 * blockScale, childrenRect.width) // Увеличено с 250

                                        anchors.centerIn: parent
                                        spacing: 10 * blockScale
                                    }

                                    Button {
                                        id: rightActivateBtn
                                        enabled: !main.debugMode
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 5 * blockScale
                                        width: 35 * blockScale
                                        height: 35 * blockScale
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
                                            border.color : borderColor
                                            border.width : 1 * blockScale
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
                                            font.pixelSize: 18 * blockScale
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
                                                main.updateFlowArrows();
                                            }
                                            main.activeContainer = rightContainer
                                        }
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
            obrabotka.myPriem(data)
        } else if(a === 2){
            obrabotka.startDebugging(data, main.debugStartBlockId)
        }
        return data
    }

    function updateBlockHighlight() {
        var allExistingBlocks = collectAllBlocks();
        for (var i = 0; i < allExistingBlocks.length; i++) {
            var block = allExistingBlocks[i];
            if (block && typeof block.highlightInSelfAndChildren === 'function') {
                block.highlightInSelfAndChildren(main.currentDebugBlockId);
            }
            if (block && block._blockCanvasRef) {
                block._blockCanvasRef.requestPaint();
            }
        }
    }

    onCurrentDebugBlockIdChanged: updateBlockHighlight()
    onErrorBlockIdsChanged: updateBlockHighlight()

    function loadAlgorithm(algorithmData, parentContainer) {
        var children = parentContainer.children
        for (var i = children.length - 1; i >= 0; i--) {
            children[i].destroy();
        }
        main.blockIdCounter = 0

        function createBlocksRecursive(dataArray, container) {
            for (var i = 0; i < dataArray.length; i++) {
                var blockData = dataArray[i];
                var newBlock = spisok.createObject(container, {
                    "blockType": blockData.type,
                    "uniqueId": blockData.uniqueId,
                    "customColor": blockData.customColor || "transparent"
                });

                if (blockData.uniqueId >= main.blockIdCounter) {
                    main.blockIdCounter = blockData.uniqueId + 1;
                }

                if (blockData.type === "усл") {
                    newBlock.setTextFields(blockData.type, blockData.input);
                    createBlocksRecursive(blockData.trueBranch, newBlock.findChild("leftContainer", true));
                    createBlocksRecursive(blockData.falseBranch, newBlock.findChild("rightContainer", true));
                } else if (blockData.type === "счетчик") {
                    var counterParts = blockData.input.match(/(\w+)\s*=\s*(.+)\s*to\s*(.+)\s*step\s*(.+)/);
                    if(counterParts) {
                        newBlock.setTextFields(blockData.type, null, counterParts[1].trim(), counterParts[2].trim(), counterParts[3].trim(), counterParts[4].trim());
                    }
                    createBlocksRecursive(blockData.loopBody, newBlock.findChild("centerContainerCounter", true));
                } else if (blockData.type === "предусл" || blockData.type === "постусл") {
                    newBlock.setTextFields(blockData.type, blockData.input);
                    var loopContainer = (blockData.type === "предусл") ? newBlock.findChild("centerContainer", true) : newBlock.findChild("centerContainerPost", true);
                    createBlocksRecursive(blockData.loopBody, loopContainer);
                } else if (blockData.type !== "начало" && blockData.type !== "конец") {
                    newBlock.setTextFields(blockData.type, blockData.input);
                }
            }
        }
        createBlocksRecursive(algorithmData, parentContainer);
        main.updateFlowArrows();
    }

    // Window выбора цвета для блоков
    Window {
        id: colorWindow
        width: 300
        height: 400
        modality: Qt.NonModal
        flags: Qt.Window
        visible: false
        title: "Выбор цвета"
        color: panelColor

        property var blockItem: null

        function openWindow() {
            colorWindow.x = main.x + (main.width - colorWindow.width) / 2
            colorWindow.y = main.y + (main.height - colorWindow.height) / 2
            colorWindow.visible = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            Text {
                text: "Выберите цвет для блока"
                color: textColor
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
            }

            Grid {
                id: colorGrid
                width: 280
                height: 220
                columns: 6
                spacing: 5
                Layout.alignment: Qt.AlignHCenter

                property var colors: [
                    "#FF0000", "#00FF00", "#0000FF", "#FFFF00",
                    "#FF00FF", "#00FFFF", "#FFA500", "#800080",
                    "#008000", "#000080", "#A52A2A", "#808080",
                    "#C0C0C0", "#FFC0CB", "#90EE90", "#ADD8E6",
                    "#4CAF50", "#FFEB3B", "#FF9800", "#9C27B0",
                    "#673AB7", "#3F51B5", "#2196F3", "#03A9F4",
                    "#00BCD4", "#009688", "#8BC34A", "#CDDC39",
                    "#FFC107", "#FF5722", "#795548", "#607D8B",
                    "#E91E63", "#F44336", "#9E9E9e", "#424242"
                ]

                Repeater {
                    model: colorGrid.colors

                    Rectangle {
                        id: colorTile
                        width: (colorGrid.width - colorGrid.spacing * (colorGrid.columns - 1)) / colorGrid.columns
                        height: width
                        color: modelData
                        radius: 5
                        border.color: {
                            if (colorTileMouseArea.pressed) return Qt.darker(modelData, 1.5)
                            if (colorTileMouseArea.hovered) return Qt.lighter(modelData, 1.5)
                            return borderColor
                        }
                        border.width: colorTileMouseArea.hovered ? 3 : 2

                        // Анимация наведения и нажатия
                        scale: colorTileMouseArea.pressed ? 0.85 : (colorTileMouseArea.hovered ? 1.1 : 1.0)
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        // Эффект тени при наведении
                        layer.enabled: !!colorTileMouseArea.hovered


                        MouseArea {
                            id: colorTileMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (colorWindow.blockItem) {
                                    colorWindow.blockItem.customColor = modelData;
                                    if (colorWindow.blockItem._blockCanvasRef) {
                                        colorWindow.blockItem._blockCanvasRef.requestPaint();
                                    } else {
                                        console.warn("blockCanvas not registered for block ID:", colorWindow.blockItem.uniqueId);
                                    }
                                }
                                colorWindow.close();
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 10
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 15

                Button {
                    text: "Сбросить цвет"
                    Layout.fillWidth: true
                    hoverEnabled: true

                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        if (colorWindow.blockItem) {
                            colorWindow.blockItem.customColor = main.getBlockColor(colorWindow.blockItem.blockType);
                            if (colorWindow.blockItem._blockCanvasRef) {
                                colorWindow.blockItem._blockCanvasRef.requestPaint();
                            }
                        } else {
                            console.warn("blockCanvas not registered for block ID:", colorWindow.blockItem.uniqueId);
                        }
                        colorWindow.close();
                    }
                }

                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    hoverEnabled: true

                    background: Rectangle {
                        color: {
                            if (parent.pressed) {
                                var c = Qt.darker("#757575", 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (parent.hovered) {
                                var c = Qt.lighter("#757575", 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return "#9e9e9e"
                            }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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

                    onClicked: colorWindow.close()
                }
            }
        }
    }

    // Window настроек
    Window {
        id: settingsWindow
        width: 350
        height: 470
        modality: Qt.NonModal
        flags: Qt.Window
        visible: false
        title: "Настройки"
        color: panelColor

        function openWindow() {
            settingsWindow.x = main.x + (main.width - settingsWindow.width) / 2
            settingsWindow.y = main.y + (main.height - settingsWindow.height) / 2
            settingsWindow.visible = true

            // Set ComboBox current index based on currentThemeId
            for (var i = 0; i < themeModel.count; ++i) {
                if (themeModel.get(i).themeId === main.currentThemeId) {
                    themeSelector.currentIndex = i;
                    break;
                }
            }
        }

        Connections {
            target: settingsWindow
            function onClosing(closeEvent) {
                main.saveSettings();
                closeEvent.accepted = true; // Use accepted property
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8  // Уменьшен spacing между элементами

            Text {
                text: "Настройки"
                color: textColor
                font.bold: true
                font.pixelSize: 20
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Выберите тему:"
                color: textColor
                font.bold: true
                font.pixelSize: 16
            }

            ComboBox {
                id: themeSelector
                width: parent.width
                height: 45  // Уменьшена высота
                model: ListModel {
                    id: themeModel
                    ListElement { themeName: "Темная"; themeId: "dark" }
                    ListElement { themeName: "Белая"; themeId: "ant" }
                    ListElement { themeName: "Синяя"; themeId: "blue" }
                    ListElement { themeName: "Зеленая"; themeId: "green" }
                    ListElement { themeName: "Фиолетовая"; themeId: "purple" }
                    ListElement { themeName: "Оранжевая"; themeId: "orange" }
                    ListElement { themeName: "Пурпурный туман"; themeId: "purple_mist" }
                }
                currentIndex: 0

                background: Rectangle {
                    id: themeComboBg
                    color: buttonColor
                    border.color: themeSelector.hovered ? Qt.lighter(borderColor, 1.3) : borderColor
                    border.width: 2
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                    }
                }

                contentItem: Text {
                    text: themeSelector.currentIndex >= 0 ? themeModel.get(themeSelector.currentIndex).themeName : ""
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                    font.pixelSize: 16
                    font.bold: true
                }

                delegate: ItemDelegate {
                    id: themeDelegateItem
                    width: parent.width
                    height: 35  // Уменьшена высота элемента
                    hoverEnabled: true
                    highlighted: ListView.isCurrentItem

                    background: Rectangle {
                        color: themeDelegateItem.highlighted ? hoverColor :
                                (themeDelegateItem.hovered ? Qt.lighter(panelColor, 1.15) : panelColor)
                        border.color: borderColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: model.themeName
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                        font.pixelSize: 16
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

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        var themeId = themeModel.get(currentIndex).themeId;
                        switch(themeId) {
                            case "dark":
                                resetToDarkTheme();
                                break;
                            case "ant":
                                setAntLightTheme();
                                break;
                            case "blue":
                                setBlueTheme();
                                break;
                            case "green":
                                setGreenTheme();
                                break;
                            case "purple":
                                setPurpleTheme();
                                break;
                            case "orange":
                                setOrangeTheme();
                                break;
                            case "purple_mist":
                                setPurpleMistTheme();
                                break;
                        }
                    }
                }
            }

            Text {
                text: "Масштаб кнопок: " + Math.round(buttonsZoomLevel * 100) + "%"
                color: textColor
                font.pixelSize: 16
            }

            Slider {
                id: buttonsZoomSlider
                width: parent.width
                from: 0.5
                to: 2.0
                value: buttonsZoomLevel
                stepSize: 0.1
                onValueChanged: {
                    buttonsZoomLevel = value
                    saveSettings()
                }

                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: parent.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: buttonColor

                    Rectangle {
                        width: parent.width * (parent.parent.value - parent.parent.from) / (parent.parent.to - parent.parent.from)
                        height: parent.height
                        color: hoverColor
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: parent.pressed ? pressedColor : (parent.hovered ? hoverColor : buttonColor)
                    border.color: borderColor
                    border.width: 2
                }
            }

            Text {
                text: "Масштаб блоков: " + Math.round(blocksZoomLevel * 100) + "%"
                color: textColor
                font.pixelSize: 16
            }

            Slider {
                id: blocksZoomSlider
                width: parent.width
                from: 0.5
                to: 2.0
                value: blocksZoomLevel
                stepSize: 0.1
                onValueChanged: {
                    blocksZoomLevel = value
                    saveSettings()
                }

                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: parent.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: buttonColor

                    Rectangle {
                        width: parent.width * (parent.parent.value - parent.parent.from) / (parent.parent.to - parent.parent.from)
                        height: parent.height
                        color: hoverColor
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: parent.pressed ? pressedColor : (parent.hovered ? hoverColor : buttonColor)
                    border.color: borderColor
                    border.width: 2
                }
            }

            Rectangle {
                width: parent.width
                height: 2
                color: borderColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
            ColumnLayout{

                width: parent.width
                spacing: 5
                // Кнопка справки
                Button {
                    id: helpButton
                    text: "Справка"
                    Layout.fillWidth: true
                    height: 35  // Уменьшена высота кнопок
                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        helpWindow.openWindow();
                    }
                }
            }
            Text {
                text: "Файл"
                color: textColor
                font.bold: true
                font.pixelSize: 16
            }

            ColumnLayout {
                width: parent.width
                spacing: 5  // Уменьшен spacing между кнопками

                Button {
                    text: "Создать новый"
                    Layout.fillWidth: true
                    height: 35  // Уменьшена высота кнопок
                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        newFileDialog.open();
                        settingsWindow.close();
                    }
                }
                Button {
                    text: "Открыть"
                    Layout.fillWidth: true
                    height: 35
                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        openDialog.open();
                        settingsWindow.close();
                    }
                }
                Button {
                    text: "Сохранить"
                    Layout.fillWidth: true
                    height: 35
                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        if (obrabotka.currentFilePath) {
                            var data = main.collectData(0);
                            obrabotka.saveAlgorithmToFile(data, Qt.resolvedUrl("file:///" + obrabotka.currentFilePath));
                        } else {
                            saveAsDialog.open();
                        }
                        settingsWindow.close();
                    }
                }
                 Button {
                    text: "Сохранить как..."
                    Layout.fillWidth: true
                    height: 35
                    background: Rectangle {
                        color: {
                            if (!!parent.pressed) {
                                var c = Qt.darker(buttonColor, 1.25);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else if (!!parent.hovered) {
                                var c = Qt.lighter(buttonColor, 1.15);
                                return Qt.rgba(c.r, c.g, c.b, 1);
                            } else return buttonColor
                        }
                        border.color: borderColor
                        border.width: 1
                        radius: 5

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
                        saveAsDialog.open();
                        settingsWindow.close();
                    }
                }
            }
        }
    }

    // Window справки с вкладками
    Window {
        id: helpWindow
        width: 600
        height: 500
        modality: Qt.NonModal
        flags: Qt.Window
        visible: false
        title: "Справка"
        color: panelColor

        function openWindow() {
            helpWindow.x = main.x + (main.width - helpWindow.width) / 2
            helpWindow.y = main.y + (main.height - helpWindow.height) / 2
            helpWindow.visible = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Справка по приложению"
                color: textColor
                font.bold: true
                font.pixelSize: 24
                Layout.alignment: Qt.AlignHCenter
            }

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                currentIndex: 0
                background: Rectangle { color: "transparent"; border.width: 0 }

                TabButton {
                    text: "Как пользоваться"
                    width: implicitWidth

                    background: Rectangle {
                        color: parent.checked ? main.buttonColor : main.panelColor
                        border.color: main.borderColor
                        border.width: parent.checked ? 1 : 0 // Border only for checked tab
                        radius: 5

                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: main.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                }
                TabButton {
                    text: "Что такое алгоритмы"
                    width: implicitWidth

                    background: Rectangle {
                        color: parent.checked ? main.buttonColor : main.panelColor
                        border.color: main.borderColor
                        border.width: parent.checked ? 1 : 0
                        radius: 5

                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: main.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                }
                TabButton {
                    text: "Особенности синтаксиса"
                    width: implicitWidth

                    background: Rectangle {
                        color: parent.checked ? main.buttonColor : main.panelColor
                        border.color: main.borderColor
                        border.width: parent.checked ? 1 : 0
                        radius: 5

                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        color: main.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                }
            }

            StackLayout {
                id: stackLayout
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // Вкладка 1: Как пользоваться
                ScrollView {
                    id: tab1
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    clip: true

                    Text {
                        id: tab1Text
                        width: stackLayout.width - 20
                        wrapMode: Text.WordWrap
                        color: textColor
                        font.pixelSize: 16
                        text: "КАК ПОЛЬЗОВАТЬСЯ ПРИЛОЖЕНИЕМ
1. СОЗДАНИЕ АЛГОРИТМА:
   • При нажатии на кнопку блока из верхней панели появится блок в активированной области
   • Выберите тип блока из выпадающего списка и нажмите на активированную область там появится блоки,
выбранный в выподающего списка
   • Для добавления блоков в ветки условий или циклов активируйте соответствующую область кнопкой 'A'

2. РЕДАКТИРОВАНИЕ БЛОКОВ:
   • Правый клик по блоку также удаляет его
   • Левый клик по блоку начинает ввод в него
   • Для вставки блока выше/низу используйте кнопки со стрелками на блоке,
тогда появится блок выбранный в выподающем списке
   • Для изменения цвета блока нажмите кнопку 'Ц' на блоке

3. РАБОТА С АЛГОРИТМОМ:
   • 'Запуск' - выполнение алгоритма
   • 'Отладка' - пошаговое выполнение с просмотром значений переменных
   • В отладке используйте кнопки 'Назад'/'Вперёд' для навигации
   • Установите точку начала отладки кнопкой 'О' на блоке

4. УПРАВЛЕНИЕ ФАЙЛАМИ:
   • 'Создать новый' - создание нового файла алгоритма
   • 'Открыть' - загрузка существующего алгоритма
   • 'Сохранить'/'Сохранить как...' - сохранение алгоритма

5. НАСТРОЙКИ:
   • Выбор темы оформления
   • Настройка масштаба кнопок и блоков
   • Все настройки сохраняются автоматически

6. РАБОЧАЯ ОБЛАСТЬ:
   • Используйте колесико мыши с зажатым Ctrl для масштабирования"
                    }
                }

                // Вкладка 2: Что такое алгоритмы
                ScrollView {
                    id: tab2
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    clip: true

                    Text {
                        id: tab2Text
                        width: stackLayout.width - 20
                        wrapMode: Text.WordWrap
                        color: textColor
                        font.pixelSize: 16
                        text: "ЧТО ТАКОЕ АЛГОРИТМЫ

1. ОПРЕДЕЛЕНИЕ:
   Алгоритм - это конечная последовательность четко определенных инструкций, предназначенных для выполнения конкретной задачи.

2. ТИПЫ БЛОКОВ В ПРИЛОЖЕНИИ:

   • НАЧАЛО/КОНЕЦ:
     - Начало: точка входа в алгоритм
     - Конец: точка выхода из алгоритма

   • ВВОД/ВЫВОД:
     - Ввод: получение данных от пользователя
     - Вывод: отображение данных пользователю

   • ДЕЙСТВИЕ:
     - Выполнение операций и присваивание значений
     - Формат: переменная = выражение
     - Пример: x = 1 + 1

   • УСЛОВИЕ:
     - Ветвление алгоритма по условию
     - Имеет две ветки: 'истина' и 'ложь'
     - Пример: x > 10

   • СЧЕТЧИК:
     - Цикл с фиксированным количеством итераций
     - Формат: переменная = начало to конец step шаг
     - Пример: i = 1 to 10 step 1

   • ПРЕДУСЛОВИЕ:
     - Цикл с проверкой условия перед выполнением (while)
     - Тело выполняется, пока условие истинно

   • ПОСТУСЛОВИЕ:
     - Цикл с проверкой условия после выполнения (do-while)
     - Тело выполняется хотя бы один раз

3. СТРУКТУРЫ АЛГОРИТМОВ:
   • Линейные: последовательное выполнение блоков
   • Ветвящиеся: использование условий
   • Циклические: повторение блоков

4. ПРИМЕР ПРОСТОГО АЛГОРИТМА:
   1. Начало
   2. Ввод числа n
   3. Если n > 0
      • Вывод 'Положительное'
   4. Иначе
      • Вывод 'Отрицательное или ноль'
   5. Конец"
                    }
                }

                // Вкладка 3: Особенности синтаксиса
                ScrollView {
                    id: tab3
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    clip: true

                    Text {
                        id: tab3Text
                        width: stackLayout.width - 20
                        wrapMode: Text.WordWrap
                        color: textColor
                        font.pixelSize: 16
                        text: "ОСОБЕННОСТИ СИНТАКСИСА

1. ОБЩИЕ ПРАВИЛА:
   • Регистр символов имеет значение
   • Пробелы не влияют на выполнение, но улучшают читаемость
   • Каждый блок должен быть правильно заполнен

2. ВЫРАЖЕНИЯ В БЛОКАХ:

   • ВВОД:
     - Укажите имя переменной для ввода
     - Пример: x

   • ВЫВОД:
     - Укажите имя переменной или выражение для вывода
     - Пример: result или 'Результат: ' + result

   • ДЕЙСТВИЕ:
     - Формат: переменная = выражение
     - Поддерживаемые операторы:
       + сложение
       - вычитание
       * умножение
       / деление
       % остаток от деления
     - Примеры:
       x = 10
       y = x + 5
       z = (a + b) * 2

   • УСЛОВИЯ:
     - Поддерживаемые операторы сравнения:
       > больше
       < меньше
       >= больше или равно
       <= меньше или равно
       == равно
       != не равно
     - Логические операторы:
       && И (и)
       || ИЛИ (или)
       ! НЕ (не)
     - Примеры:
       x > 10
       (age >= 18) && (age <= 65)
       !found

   • СЧЕТЧИК:
     - Формат: переменная, шаг, начоло, конец
3. РАБОТА С ПЕРЕМЕННЫМИ:
   • Переменные создаются при первом использовании
   • Типы определяются автоматически:
     - Числа: 10, 3.14, -5
     - Строки: 'текст', 'Hello'
     - Булевы: true, false
   • Динамическая типизация

4. ОПЕРАЦИИ СО СТРОКАМИ:
   • Конкатенация: 'Hello ' + 'World'
   • Длина строки: len(s)
   • Индексация: s[0], s[-1]
   • Срезы: s[1:4], s[:5], s[2:]

5. ПРОВЕРКА СИНТАКСИСА:
   • Приложение проверяет синтаксис перед выполнением
   • Ошибки выделяются красным цветом
   • Сообщения об ошибках выводятся в консоль

6. ОГРАНИЧЕНИЯ:
   • Максимальное количество итераций в циклах: 1000
   • Вложенность блоков ограничена только памятью
   • Нет поддержки пользовательских функций"
                    }
                }
            }

            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 40
                Layout.preferredWidth: 120

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
                    font.pixelSize: 18
                    font.bold: true
                }

                onClicked: helpWindow.close()
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
                ctx.fillStyle = main.getBlockColor(blockType)
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
