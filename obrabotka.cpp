// obrabotka.cpp
#include "obrabotka.h"
#include <QQmlEngine>
#include <QDebug>
#include <QString>
#include <QRegularExpression>
#include <stack>
#include <QVariantList>
#include <QMutex>
#include <QCoreApplication>
#include <QThread>
#include <QWaitCondition>
#include <cmath>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QProcess>
#include <QSettings>

// ============================================================================
// ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С СОСТОЯНИЕМ ПЕРЕМЕННЫХ
// ============================================================================

// Преобразует внутреннюю карту переменных в QVariantMap для передачи в QML
QVariantMap Obrabotka::convertToQmlVariantMap() const
{
    QVariantMap map;
    for (auto it = peremennieMap.constBegin(); it != peremennieMap.constEnd(); ++it) {
        QVariant value = it.value().value;
        if (value.canConvert<QVariantList>()) {
            QJsonDocument doc(QJsonArray::fromVariantList(value.toList()));
            map[it.key()] = doc.toJson(QJsonDocument::Compact);
        } else {
            map[it.key()] = value; // Keep original QVariant for non-array types
        }
    }
    return map;
}

// Восстанавливает состояние переменных из QVariantMap (для отладки/отката)
void Obrabotka::restoreStateFromVariantMap(const QVariantMap& state)
{
    peremennieMap.clear();
    for (auto it = state.constBegin(); it != state.constEnd(); ++it) {
        peremennieMap[it.key()] = VariableInfo(it.value(), "auto");
    }
}

// Конструктор класса обработчика алгоритмов
Obrabotka::Obrabotka(QObject *parent) : QObject(parent)
{
}

// ============================================================================
// РАБОТА С ТИПАМИ ДАННЫХ
// ============================================================================

// Определяет тип переменной на основе QVariant
Obrabotka::VariableType Obrabotka::determineType(const QVariant& value)
{
    switch (value.typeId()) {
    case QMetaType::Int:
    case QMetaType::Double: return Numeric;
    case QMetaType::QString: return String;
    case QMetaType::Bool: return Boolean;
    case QMetaType::QVariantList: return Array;
    default: return Unknown;
    }
}

// Преобразует перечисление типа в строковое представление
QString Obrabotka::typeToString(VariableType type)
{
    switch (type) {
    case Numeric: return "numeric";
    case String: return "string";
    case Boolean: return "bool";
    case Array: return "array";
    default: return "unknown";
    }
}

// Определяет тип переменной по строковому представлению (для ввода пользователя)
Obrabotka::VariableType Obrabotka::determineTypeFromString(const QString& value)
{
    if (value.length() >= 2 && value.startsWith('"') && value.endsWith('"')) {
        return String;
    }
    if (value.toLower() == "true" || value.toLower() == "false") {
        return Boolean;
    }
    bool ok;
    value.toDouble(&ok);
    if (ok) return Numeric;
    return String;
}

// Проверяет, можно ли преобразовать строку в число, и возвращает результат
bool Obrabotka::canConvertToNumber(const QString& str, double& result)
{
    if (str.length() >= 2 && str.startsWith('"') && str.endsWith('"')) {
        return false;
    }
    bool ok;
    result = str.toDouble(&ok);
    return ok;
}

// Проверяет, является ли число целым (с точностью до 1e-10)
bool Obrabotka::isInteger(double value)
{
    return std::fabs(value - std::round(value)) < 1e-10;
}

// ============================================================================
// АРИФМЕТИЧЕСКИЕ И ЛОГИЧЕСКИЕ ОПЕРАЦИИ
// ============================================================================

// Выполняет сложение двух значений с проверкой типов (строки конкатенируются, числа складываются)
QVariant Obrabotka::addValues(const QVariant& left, const QVariant& right)
{
    qDebug() << "addValues called with left:" << left << "type:" << typeToString(determineType(left))
    << ", right:" << right << "type:" << typeToString(determineType(right));
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    // Строгая проверка: нельзя складывать строку с числом без явного приведения
    if ((leftType == String && rightType == Numeric) || (leftType == Numeric && rightType == String)) {
        setError("Ошибка: Несовместимые типы для операции сложения. Нельзя складывать строку с числом без явного приведения типа (например, str(число) или использование кавычек).");
        return QVariant();
    }

    if (leftType == String || rightType == String) {
        QString result = left.toString() + right.toString();
        qDebug() << "addValues (string concat) result:" << result;
        return result;
    }

    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal + rightVal;
        qDebug() << "addValues (numeric sum) result:" << result;
        return QVariant(result);
    }

    setError("Ошибка: Несовместимые типы для операции сложения.");
    return QVariant();
}

// Выполняет вычитание двух числовых значений
QVariant Obrabotka::subtractValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal - rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции вычитания.");
    return QVariant();
}

// Выполняет умножение двух числовых значений
QVariant Obrabotka::multiplyValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        double result = leftVal * rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции умножения.");
    return QVariant();
}

// Выполняет деление двух числовых значений с проверкой деления на ноль
QVariant Obrabotka::divideValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        double rightVal = right.toDouble();
        if (qFuzzyIsNull(rightVal)) {
            setError("Ошибка: Деление на ноль.");
            return QVariant();
        }
        double leftVal = left.toDouble();
        double result = leftVal / rightVal;
        return QVariant(result);
    }
    setError("Ошибка: Несовместимые типы для операции деления.");
    return QVariant();
}

// Выполняет операцию по модулю (%) с проверкой целочисленности и деления на ноль
QVariant Obrabotka::moduloValues(const QVariant& left, const QVariant& right)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);
    if (leftType == Numeric && rightType == Numeric) {
        bool leftOk, rightOk;
        int leftVal = left.toInt(&leftOk);
        int rightVal = right.toInt(&rightOk);
        if (!leftOk || !rightOk) {
            setError("Ошибка: Для операции по модулю требуются целые числа.");
            return QVariant();
        }
        if (rightVal == 0) {
            setError("Ошибка: Деление на ноль при операции по модулю.");
            return QVariant();
        }
        return QVariant(leftVal % rightVal);
    }
    setError("Ошибка: Несовместимые типы для операции по модулю.");
    return QVariant();
}

// Сравнивает два значения по заданному оператору (>, <, ==, !=, >=, <=)
bool Obrabotka::compareValues(const QVariant& left, const QVariant& right, const QString& op)
{
    VariableType leftType = determineType(left);
    VariableType rightType = determineType(right);

    if (leftType == String && rightType == String) {
        QString leftStr = left.toString();
        QString rightStr = right.toString();
        if (op == "==") return leftStr == rightStr;
        if (op == "!=") return leftStr != rightStr;
        setError("Ошибка синтаксиса: для строк разрешены только операции == и != ");
        return false;
    }

    if (leftType == Numeric && rightType == Numeric) {
        double leftVal = left.toDouble();
        double rightVal = right.toDouble();
        if (op == ">") return leftVal > rightVal;
        if (op == "<") return leftVal < rightVal;
        if (op == ">=") return leftVal >= rightVal;
        if (op == "<=") return leftVal <= rightVal;
        if (op == "==") return qFuzzyCompare(leftVal, rightVal);
        if (op == "!=") return !qFuzzyCompare(leftVal, rightVal);
    }

    if (leftType == Boolean && rightType == Boolean) {
        bool leftVal = left.toBool();
        bool rightVal = right.toBool();
        if (op == "==") return leftVal == rightVal;
        if (op == "!=") return leftVal != rightVal;
    }

    setError("Ошибка: Несовместимые типы для операции сравнения.");
    return false;
}

// ============================================================================
// ОПЕРАЦИИ СО СТРОКАМИ И МАССИВАМИ (СРЕЗЫ)
// ============================================================================

// Возвращает символ строки по индексу с поддержкой отрицательных индексов
QVariant Obrabotka::getStringIndexedValue(const QString& str, int index)
{
    clearError();
    int len = str.length();

    if (index < 0) {
        index = len + index;
    }

    if (index < 0 || index >= len) {
        setError("Ошибка: Индекс строки " + QString::number(index) + " выходит за границы (длина " + QString::number(len) + ").");
        return QVariant();
    }

    return QVariant(QString(str.at(index)));
}

// Возвращает срез строки с поддержкой отрицательных индексов и шага, как в Python
QVariant Obrabotka::getStringSlice(const QString& str, const QVariant& startVar, const QVariant& endVar, const QVariant& stepVar)
{
    clearError();
    int len = str.length();

    int step = 1;
    if (stepVar.isValid() && !stepVar.isNull()) {
        bool ok;
        int st = stepVar.toInt(&ok);
        if (!ok) {
            setError("Ошибка: Шаг среза должен быть числом.");
            return QVariant();
        }
        step = st;
        if (step == 0) {
            setError("Ошибка: Шаг среза не может быть равен нулю.");
            return QVariant();
        }
    }

    int start, end;
    if (step > 0) {
        // По умолчанию для положительного шага
        start = 0;
        end = len;
        if (startVar.isValid() && !startVar.isNull()) {
            bool ok;
            int s = startVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Начальный индекс среза должен быть числом.");
                return QVariant();
            }
            start = s;
        }
        if (endVar.isValid() && !endVar.isNull()) {
            bool ok;
            int e = endVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Конечный индекс среза должен быть числом.");
                return QVariant();
            }
            end = e;
        }
    } else {
        // По умолчанию для отрицательного шага
        start = len - 1;
        end = -len - 1; // после нормализации станет -1
        if (startVar.isValid() && !startVar.isNull()) {
            bool ok;
            int s = startVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Начальный индекс среза должен быть числом.");
                return QVariant();
            }
            start = s;
        }
        if (endVar.isValid() && !endVar.isNull()) {
            bool ok;
            int e = endVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Конечный индекс среза должен быть числом.");
                return QVariant();
            }
            end = e;
        }
    }

    // Нормализация отрицательных индексов
    if (start < 0) start = len + start;
    if (end < 0) end = len + end;

    // Корректировка границ в зависимости от шага
    if (step > 0) {
        start = qMax(0, start);
        end = qMin(len, end);
    } else {
        start = qMin(len - 1, start);
        end = qMax(-1, end);
    }

    QString result;
    if (step > 0) {
        for (int i = start; i < end; i += step) {
            if (i >= 0 && i < len) result.append(str.at(i));
        }
    } else {
        for (int i = start; i > end; i += step) {
            if (i >= 0 && i < len) result.append(str.at(i));
        }
    }

    return QVariant(result);
}

// Возвращает срез массива (списка) с поддержкой отрицательных индексов и шага
QVariant Obrabotka::getArraySlice(const QVariantList& list, const QVariant& startVar, const QVariant& endVar, const QVariant& stepVar)
{
    clearError();
    int len = list.size();

    int step = 1;
    if (stepVar.isValid() && !stepVar.isNull()) {
        bool ok;
        int st = stepVar.toInt(&ok);
        if (!ok) {
            setError("Ошибка: Шаг среза должен быть числом.");
            return QVariant();
        }
        step = st;
        if (step == 0) {
            setError("Ошибка: Шаг среза не может быть равен нулю.");
            return QVariant();
        }
    }

    int start, end;
    if (step > 0) {
        start = 0;
        end = len;
        if (startVar.isValid() && !startVar.isNull()) {
            bool ok;
            int s = startVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Начальный индекс среза должен быть числом.");
                return QVariant();
            }
            start = s;
        }
        if (endVar.isValid() && !endVar.isNull()) {
            bool ok;
            int e = endVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Конечный индекс среза должен быть числом.");
                return QVariant();
            }
            end = e;
        }
    } else {
        start = len - 1;
        end = -len - 1;
        if (startVar.isValid() && !startVar.isNull()) {
            bool ok;
            int s = startVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Начальный индекс среза должен быть числом.");
                return QVariant();
            }
            start = s;
        }
        if (endVar.isValid() && !endVar.isNull()) {
            bool ok;
            int e = endVar.toInt(&ok);
            if (!ok) {
                setError("Ошибка: Конечный индекс среза должен быть числом.");
                return QVariant();
            }
            end = e;
        }
    }

    if (start < 0) start = len + start;
    if (end < 0) end = len + end;

    if (step > 0) {
        start = qMax(0, start);
        end = qMin(len, end);
    } else {
        start = qMin(len - 1, start);
        end = qMax(-1, end);
    }

    QVariantList result;
    if (step > 0) {
        for (int i = start; i < end; i += step) {
            if (i >= 0 && i < len) result.append(list.at(i));
        }
    } else {
        for (int i = start; i > end; i += step) {
            if (i >= 0 && i < len) result.append(list.at(i));
        }
    }

    return QVariant(result);
}

// ============================================================================
// ВСТРОЕННЫЕ ФУНКЦИИ (len, int, str)
// ============================================================================

// Преобразует QVariant в целое число (если возможно)
QVariant Obrabotka::stringToInt(const QVariant& arg)
{
    clearError();
    bool ok;
    double doubleVal = arg.toDouble(&ok);
    if (!ok) {
        setError("Ошибка: Невозможно преобразовать '" + arg.toString() + "' в число.");
        return QVariant();
    }
    if (!isInteger(doubleVal)) {
        setError("Ошибка: Невозможно преобразовать '" + arg.toString() + "' в целое число (найдено нецелое число).");
        return QVariant();
    }
    return QVariant(static_cast<int>(doubleVal));
}

// Преобразует QVariant в строковое представление (для массивов — JSON)
QVariant Obrabotka::anyToString(const QVariant& arg)
{
    clearError();
    if (arg.typeId() == QMetaType::QVariantList) {
        QJsonDocument doc(QJsonArray::fromVariantList(arg.toList()));
        return QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
    }
    return arg.toString();
}

// Универсальный обработчик для вызова встроенных функций
QVariant Obrabotka::callBuiltinFunction(const QString& funcName, const QVariantList& args)
{
    clearError();
    if (funcName == "len") {
        if (args.count() != 1) {
            setError("Функция 'len()' принимает 1 аргумент.");
            return QVariant();
        }
        QVariant arg = args.first();
        VariableType argType = determineType(arg);
        if (argType == Array) {
            return arg.toList().size();
        } else if (argType == String) {
            return arg.toString().length();
        } else {
            setError("Функция 'len()' может быть применена только к массивам или строкам.");
            return QVariant();
        }
    } else if (funcName == "int") {
        if (args.count() != 1) {
            setError("Функция 'int()' принимает 1 аргумент.");
            return QVariant();
        }
        return stringToInt(args.first());
    } else if (funcName == "str") {
        if (args.count() != 1) {
            setError("Функция 'str()' принимает 1 аргумент.");
            return QVariant();
        }
        return anyToString(args.first());
    } else {
        setError("Неизвестная встроенная функция: '" + funcName + "'.");
        return QVariant();
    }
}

// ============================================================================
// МЕТОДЫ ДЛЯ РАБОТЫ С МАССИВАМИ (APPEND)
// ============================================================================

void Obrabotka::executeMethod(const QString& targetName, const QString& methodName, const QVariantList& args) {
    clearError();
    qDebug() << "executeMethod: target=" << targetName << ", method=" << methodName << ", args=" << args;

    QVariant targetVar;
    QString actualTargetVarName;
    int targetArrayIndex = -1;

    static QRegularExpression arrayAccessRegex(R"(^(\w+)\s*\[(.+)\]$)");
    QRegularExpressionMatch arrayAccessMatch = arrayAccessRegex.match(targetName);
    if (arrayAccessMatch.hasMatch()) {
        actualTargetVarName = arrayAccessMatch.captured(1);
        QString indexExpr = arrayAccessMatch.captured(2);

        QVariant tempArray = getValue(actualTargetVarName);
        if (m_hasError) return;

        if (determineType(tempArray) != Array) {
            setError("Переменная '" + actualTargetVarName + "' не является массивом. Невозможно вызвать метод на элементе.");
            return;
        }

        QVariant indexVal = parseExpression(indexExpr);
        if (m_hasError) return;

        if (determineType(indexVal) != Numeric) {
            setError("Индекс массива должен быть числом.");
            return;
        }

        QVariantList list = tempArray.toList();
        int index = indexVal.toInt();

        if (index < 0) {
            index = list.size() + index;
        }

        if (index < 0 || index >= list.size()) {
            setError("Индекс массива '" + QString::number(index) + "' выходит за границы.");
            return;
        }
        targetVar = list.at(index);
        targetArrayIndex = index;

    } else {
        actualTargetVarName = targetName;
        targetVar = getValue(actualTargetVarName);
        if (m_hasError) return;
    }

    if (methodName == "append") {
        if (determineType(targetVar) == Array) {
            if (args.count() != 1) {
                setError("Метод 'append()' принимает 1 аргумент.");
                return;
            }
            QVariantList list = targetVar.toList();
            list.append(args.first());

            if (targetArrayIndex != -1) {
                QVariant parentArray = getValue(actualTargetVarName);
                if (determineType(parentArray) != Array) {
                    setError("Внутренняя ошибка: родитель не является массивом.");
                    return;
                }
                QVariantList parentList = parentArray.toList();
                parentList[targetArrayIndex] = list;
                setValue(actualTargetVarName, QVariant(parentList), "array");
            } else {
                setValue(actualTargetVarName, QVariant(list), "array");
            }
            qInfo() << "Элемент добавлен в массив '" << actualTargetVarName << "'. Новое значение: " << list;
        } else {
            setError("Метод 'append()' может быть вызван только для массивов.");
        }
    } else {
        setError("Метод '" + methodName + "' не поддерживается.");
    }
}

// ============================================================================
// СИНТАКСИЧЕСКИЙ АНАЛИЗ
// ============================================================================

void Obrabotka::addSyntaxError(const QString& message, int blockId, QVariantList& errors)
{
    QVariantMap error;
    error["message"] = message;
    error["blockId"] = blockId;
    errors.append(error);
    qDebug() << "Syntax Error (Block ID:" << blockId << "):" << message;
}

bool Obrabotka::validateExpressionSyntax(const QString& expression, int blockId, QVariantList& errors, bool isConditionalContext)
{
    bool hasLocalErrors = false;
    QString expr = expression.trimmed();

    if (expr.isEmpty()) {
        addSyntaxError("Выражение не может быть пустым.", blockId, errors);
        hasLocalErrors = true;
        return !hasLocalErrors;
    }

    if (isConditionalContext) {
        if (expr.contains('=')) {
            if (!expr.contains("==") && !expr.contains(">=") && !expr.contains("<=") && !expr.contains("!=")) {
                addSyntaxError("Оператор присваивания '=' не разрешен в условиях. Используйте '==' для сравнения.", blockId, errors);
                hasLocalErrors = true;
            }
        }
    }

    QStack<QChar> stack;
    QMap<QChar, QChar> matchingBrackets = {{'(', ')'}, {'[', ']'}};
    bool inString = false;
    for (int i = 0; i < expr.length(); ++i) {
        QChar ch = expr[i];
        if (ch == '"') {
            inString = !inString;
        } else if (!inString) {
            if (matchingBrackets.keys().contains(ch)) {
                stack.push(ch);
            } else if (matchingBrackets.values().contains(ch)) {
                if (stack.isEmpty()) {
                    addSyntaxError("Несогласованная закрывающая скобка '" + QString(ch) + "' на позиции " + QString::number(i), blockId, errors);
                    hasLocalErrors = true;
                } else {
                    QChar openBracket = stack.pop();
                    if (matchingBrackets[openBracket] != ch) {
                        addSyntaxError("Несогласованная закрывающая скобка '" + QString(ch) + "' на позиции " + QString::number(i) +
                                           ". Ожидалась '" + QString(matchingBrackets[openBracket]) + "'", blockId, errors);
                        hasLocalErrors = true;
                    }
                }
            }
        }
    }

    if (inString) {
        addSyntaxError("Незакрытая кавычка.", blockId, errors);
        hasLocalErrors = true;
    }
    if (!stack.isEmpty()) {
        addSyntaxError("Незакрытая открывающая скобка '" + QString(stack.top()) + "'.", blockId, errors);
        hasLocalErrors = true;
    }

    QRegularExpression doubleOpRegex(R"([+\-*/%]{2})");
    if (expr.contains(doubleOpRegex)) {
        addSyntaxError("Обнаружен повторяющийся оператор (например, ++, --, **).", blockId, errors);
        hasLocalErrors = true;
    }

    QString operators = "+-*/%";
    bool leadingOpError = false;
    bool trailingOpError = false;

    if (expr.length() > 0) {
        QChar firstChar = expr.at(0);
        if (operators.contains(firstChar)) {
            if (firstChar == '-') {
                QString remaining = expr.mid(1).trimmed();
                if (!remaining.isEmpty() && (remaining.at(0).isDigit() || remaining.at(0).isLetter() ||
                                             remaining.startsWith("(") || remaining.startsWith("\""))) {
                    // Корректный унарный минус
                } else {
                    leadingOpError = true;
                }
            } else {
                leadingOpError = true;
            }
        }
    }

    if (expr.length() > 0 && operators.contains(expr.at(expr.length() - 1))) {
        trailingOpError = true;
    }

    if (leadingOpError || trailingOpError) {
        addSyntaxError("Оператор в начале или конце выражения.", blockId, errors);
        hasLocalErrors = true;
    }

    QRegularExpression invalidOpSequence(R"([+\-*/%]\s*[+\-*/%])");
    QString tempCodeForOpCheck = expr;
    tempCodeForOpCheck.replace(QRegularExpression(R"(-\s*\d+)"), "1");
    tempCodeForOpCheck.replace(QRegularExpression(R"(-\s*\"[^\"]*\")"), "\"1\"");
    if (tempCodeForOpCheck.contains(invalidOpSequence)) {
        addSyntaxError("Неправильное расположение операторов (возможно, два оператора подряд).", blockId, errors);
        hasLocalErrors = true;
    }

    return !hasLocalErrors;
}

// ============================================================================
// ОБРАБОТКА ОШИБОК
// ============================================================================

void Obrabotka::setError(const QString& message)
{
    m_hasError = true;
    m_errorMessage = message;
    qCritical() << "Ошибка:" << message;
    emit errorOccurred(message);
}

void Obrabotka::clearError()
{
    m_hasError = false;
    m_errorMessage.clear();
}

// ============================================================================
// БЛОК ВВОДА ДАННЫХ
// ============================================================================

int Obrabotka::requestUserInput()
{
    qDebug() << "C++: Запрашиваем ввод пользователя";
    m_waitingForInput = true;
    emit needUserInput();
    m_loop.exec();
    return 1;
}

void Obrabotka::userInputReceived(const QString &input)
{
    qDebug() << "C++: Получен ввод:" << input;
    vvod_peremennich_polsovatela = input;
    if (m_waitingForInput) {
        m_receivedInput = input;
        m_waitingForInput = false;
        m_loop.quit();
    }
}

void Obrabotka::vvod(const QString& variableName)
{
    if (!requestUserInput()) {
        return;
    }
    QString inputValue = vvod_peremennich_polsovatela;
    VariableType detectedType = determineTypeFromString(inputValue);
    QVariant value;

    switch (detectedType) {
    case Numeric:
        value = QVariant(inputValue.toDouble());
        break;
    case Boolean:
        value = QVariant(inputValue.toLower() == "true");
        break;
    case String:
    default:
        if (inputValue.length() >= 2 && inputValue.startsWith('"') && inputValue.endsWith('"')) {
            value = QVariant(inputValue.mid(1, inputValue.length() - 2));
        } else {
            value = QVariant(inputValue);
        }
        break;
    }

    peremennieMap[variableName] = VariableInfo(value, typeToString(detectedType));
    qDebug() << "Ввод переменной:" << variableName << "=" << value;
}

// ============================================================================
// БЛОК ВЫВОДА ДАННЫХ
// ============================================================================

void Obrabotka::vivodim_functionod(QString peremen)
{
    qDebug() << "запуск вывода!";
    if (peremennieMap.contains(peremen)) {
        emit vivod(peremennieMap[peremen].value.toString());
    } else {
        emit vivod("Переменная " + peremen + " не найдена");
    }
}

// ============================================================================
// РАБОТА С ПЕРЕМЕННЫМИ
// ============================================================================

QVariant Obrabotka::getValue(const QString& name)
{
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].value;
    }
    qDebug() << "Переменная" << name << "не найдена, создаем со значением 0";
    peremennieMap[name] = VariableInfo(QVariant(0), "int");
    return QVariant(0);
}

QString Obrabotka::getType(const QString& name)
{
    if (peremennieMap.contains(name)) {
        return peremennieMap[name].type;
    }
    return "unknown";
}

void Obrabotka::setValue(const QString& name, const QVariant& value, const QString& type)
{
    QString actualType = type;
    if (type.isEmpty()) {
        actualType = typeToString(determineType(value));
    }
    peremennieMap[name] = VariableInfo(value, actualType);
}

// ============================================================================
// ТОКЕНИЗАЦИЯ И ВЫЧИСЛЕНИЕ ВЫРАЖЕНИЙ
// ============================================================================

QStringList Obrabotka::tokenize(const QString& expr)
{
    QStringList tokens;
    QString currentToken;
    bool inString = false;

    for (QChar ch : expr) {
        if (ch == '"') {
            if (inString) {
                currentToken.append(ch);
                tokens.append(currentToken);
                currentToken.clear();
                inString = false;
            } else {
                if (!currentToken.isEmpty()) {
                    tokens.append(currentToken);
                    currentToken.clear();
                }
                currentToken.append(ch);
                inString = true;
            }
        } else if (inString) {
            currentToken.append(ch);
        } else if (ch.isSpace()) {
            continue;
        } else if (ch == '(' || ch == ')' || ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '%') {
            if (!currentToken.isEmpty()) {
                tokens.append(currentToken);
                currentToken.clear();
            }
            tokens.append(QString(ch));
        } else {
            currentToken.append(ch);
        }
    }

    if (!currentToken.isEmpty()) {
        tokens.append(currentToken);
    }

    return tokens;
}

QVariant Obrabotka::evaluateTokens(QStringList& tokens)
{
    clearError();
    std::stack<int> bracketStack;

    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                setError("Ошибка: Несоответствующая закрывающая скобка.");
                return QVariant();
            }
            int start = bracketStack.top();
            bracketStack.pop();
            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }
            QVariant bracketResult = evaluateTokens(subTokens);
            if (m_hasError) return QVariant();
            tokens[start] = bracketResult.toString();
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }

    if (!bracketStack.empty()) {
        setError("Ошибка: Несоответствующая открывающая скобка.");
        return QVariant();
    }

    for (int i = 0; i < tokens.size(); ++i) {
        QString token = tokens[i].trimmed();

        if (token == "(" || token == ")" || token == "+" || token == "-" || token == "*" ||
            token == "/" || token == "%" || token == "&&" || token == "||" || token == "!" ||
            token == ">=" || token == "<=" || token == "!=" || token == "==" || token == ">" || token == "<") {
            continue;
        }

        if (token.startsWith('"') && token.endsWith('"') && token.length() >= 2) {
            continue;
        }

        double num;
        if (canConvertToNumber(token, num)) {
            tokens[i] = QVariant(num).toString();
            continue;
        }

        QVariant varValue = getValue(token);
        if (varValue.typeId() == QMetaType::QString) {
            tokens[i] = "\"" + varValue.toString() + "\"";
        } else {
            tokens[i] = varValue.toString();
        }
    }

    qDebug() << "evaluateTokens: Tokens after pre-processing:" << tokens;

    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "*" || tokens[i] == "/" || tokens[i] == "%") {
            QVariant leftVal, rightVal;

            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('"') && tokens[i-1].endsWith('"')) {
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                bool ok;
                double num = tokens[i-1].toDouble(&ok);
                if (ok) {
                    leftVal = QVariant(num);
                } else {
                    leftVal = getValue(tokens[i-1]);
                }
            }

            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('"') && tokens[i+1].endsWith('"')) {
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                bool ok;
                double num = tokens[i+1].toDouble(&ok);
                if (ok) {
                    rightVal = QVariant(num);
                } else {
                    rightVal = getValue(tokens[i+1]);
                }
            }

            QVariant result;
            if (tokens[i] == "*") {
                result = multiplyValues(leftVal, rightVal);
            } else if (tokens[i] == "/") {
                result = divideValues(leftVal, rightVal);
            } else {
                result = moduloValues(leftVal, rightVal);
            }

            if (m_hasError) return QVariant();
            tokens[i-1] = result.toString();
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    qDebug() << "evaluateTokens: Tokens after mul/div/mod:" << tokens;

    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "+" || tokens[i] == "-") {
            QVariant leftVal, rightVal;

            if (tokens[i-1].length() >= 2 && tokens[i-1].startsWith('"') && tokens[i-1].endsWith('"')) {
                leftVal = QVariant(tokens[i-1].mid(1, tokens[i-1].length() - 2));
            } else {
                bool ok;
                double num = tokens[i-1].toDouble(&ok);
                if (ok) {
                    leftVal = QVariant(num);
                } else {
                    leftVal = getValue(tokens[i-1]);
                }
            }

            if (tokens[i+1].length() >= 2 && tokens[i+1].startsWith('"') && tokens[i+1].endsWith('"')) {
                rightVal = QVariant(tokens[i+1].mid(1, tokens[i+1].length() - 2));
            } else {
                bool ok;
                double num = tokens[i+1].toDouble(&ok);
                if (ok) {
                    rightVal = QVariant(num);
                } else {
                    rightVal = getValue(tokens[i+1]);
                }
            }

            QVariant result;
            if (tokens[i] == "+") {
                result = addValues(leftVal, rightVal);
            } else {
                result = subtractValues(leftVal, rightVal);
            }

            if (m_hasError) return QVariant();
            tokens[i-1] = result.toString();
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    qDebug() << "evaluateTokens: Tokens after add/sub:" << tokens;

    if (tokens.size() != 1) {
        setError("Ошибка: Некорректное выражение.");
        return QVariant();
    }

    QString resultStr = tokens[0];
    if (resultStr.length() >= 2 && resultStr.startsWith('"') && resultStr.endsWith('"')) {
        return QVariant(resultStr.mid(1, resultStr.length() - 2));
    }
    double num;
    if (canConvertToNumber(resultStr, num)) {
        return QVariant(num);
    }
    return QVariant(resultStr);
}

// ============================================================================
// ПАРСИНГ ВЫРАЖЕНИЙ (С ПОДДЕРЖКОЙ СРЕЗОВ И ДВУМЕРНЫХ МАССИВОВ)
// ============================================================================

QVariant Obrabotka::parseExpression(const QString& expr)
{
    QString currentExpr = expr.trimmed();
    clearError();
    qDebug() << "parseExpression: Initial expr:" << expr << ", currentExpr (trimmed):" << currentExpr;

    int iterationLimit = 100;
    while (iterationLimit-- > 0) {
        bool changed = false;

        // --- Обработка литералов массивов (должна быть первой, чтобы не путать с доступом по индексу) ---
        if (currentExpr.startsWith('[') && currentExpr.endsWith(']')) {
            qDebug() << "parseExpression: Handling array literal:" << currentExpr;
            QString innerContent = currentExpr.mid(1, currentExpr.length() - 2).trimmed();
            QVariantList resultList;
            if (innerContent.isEmpty()) {
                return resultList;
            }

            QStringList elements;
            int balance = 0;
            int lastSplitPos = 0;
            bool inStringLiteral = false;

            for (int i = 0; i < innerContent.length(); ++i) {
                QChar ch = innerContent.at(i);
                if (ch == '"') {
                    inStringLiteral = !inStringLiteral;
                } else if (!inStringLiteral) {
                    if (ch == '[') balance++;
                    else if (ch == ']') balance--;
                    else if (ch == ',' && balance == 0) {
                        elements.append(innerContent.mid(lastSplitPos, i - lastSplitPos).trimmed());
                        lastSplitPos = i + 1;
                    }
                }
            }
            elements.append(innerContent.mid(lastSplitPos).trimmed());

            for (const QString& elementExpr : elements) {
                if (elementExpr.isEmpty()) {
                    setError("Ошибка: Неверный синтаксис в литерале массива (пустой элемент или лишняя запятая): " + currentExpr);
                    return QVariant();
                }
                QVariant evaluatedElement = parseExpression(elementExpr);
                if (m_hasError) return QVariant();
                resultList.append(evaluatedElement);
            }
            return resultList;
        }

        // --- НОВАЯ ОБРАБОТКА МНОГОМЕРНЫХ ИНДЕКСОВ (например, a[1][2]) ---
        static QRegularExpression multiIndexRegex(R"((\w+)((?:\[[^\[\]]*\])+))");
        QRegularExpressionMatch multiMatch = multiIndexRegex.match(currentExpr);
        if (multiMatch.hasMatch()) {
            QString fullMatch = multiMatch.captured(0);
            QString baseExpr = multiMatch.captured(1);
            QString indicesStr = multiMatch.captured(2);

            QVariant current = parseExpression(baseExpr);
            if (m_hasError) return QVariant();

            // Разбираем indicesStr на отдельные индексы
            int pos = 0;
            while (pos < indicesStr.length()) {
                if (indicesStr[pos] != '[') {
                    setError("Ожидался '[' в многомерном индексе");
                    return QVariant();
                }
                int endPos = indicesStr.indexOf(']', pos);
                if (endPos == -1) {
                    setError("Незакрытая скобка в индексе");
                    return QVariant();
                }
                QString indexExpr = indicesStr.mid(pos + 1, endPos - pos - 1);
                QVariant indexValue = parseExpression(indexExpr);
                if (m_hasError) return QVariant();

                if (determineType(indexValue) != Numeric) {
                    setError("Индекс должен быть числом");
                    return QVariant();
                }
                int index = indexValue.toInt();

                VariableType baseType = determineType(current);
                if (baseType == Array) {
                    QVariantList list = current.toList();
                    if (index < 0) index = list.size() + index;
                    if (index < 0 || index >= list.size()) {
                        setError("Индекс вне диапазона");
                        return QVariant();
                    }
                    current = list.at(index);
                } else if (baseType == String) {
                    QString str = current.toString();
                    current = getStringIndexedValue(str, index);
                    if (m_hasError) return QVariant();
                } else {
                    setError("Попытка индексации не массива и не строки");
                    return QVariant();
                }
                pos = endPos + 1;
            }

            // Замена fullMatch на строковое представление current
            QString replacementStr;
            if (determineType(current) == String) {
                replacementStr = "\"" + current.toString() + "\"";
            } else if (determineType(current) == Array) {
                replacementStr = QString::fromUtf8(QJsonDocument::fromVariant(current).toJson(QJsonDocument::Compact));
            } else {
                replacementStr = current.toString();
            }
            currentExpr.replace(fullMatch, replacementStr);
            changed = true;
            qDebug() << "parseExpression: After multi-index replacement:" << currentExpr;
            continue;
        }

        // --- Обработка срезов и доступа по индексу (одиночный) ---
        static QRegularExpression arrayAccessParseRegex(R"(([\w.\"\'\(\)\[\]\+\-, ]+?)\s*\[((?:[^\[\]]+|\[[^\[\]]*\])*?)\])");
        QRegularExpressionMatch arrayAccessMatch = arrayAccessParseRegex.match(currentExpr);
        if (arrayAccessMatch.hasMatch()) {
            QString fullMatch = arrayAccessMatch.captured(0);
            QString baseExpr = arrayAccessMatch.captured(1);
            QString indexExpr = arrayAccessMatch.captured(2);

            // Проверяем, является ли это срезом (содержит двоеточие)
            if (indexExpr.contains(':')) {
                // Срез: разбираем на части
                QStringList parts = indexExpr.split(':', Qt::KeepEmptyParts);
                while (parts.size() < 3) parts.append(QString()); // дополняем до трёх
                QString startStr = parts[0].trimmed();
                QString endStr = parts[1].trimmed();
                QString stepStr = parts[2].trimmed();

                QVariant startVar = startStr.isEmpty() ? QVariant() : parseExpression(startStr);
                if (m_hasError) return QVariant();
                QVariant endVar = endStr.isEmpty() ? QVariant() : parseExpression(endStr);
                if (m_hasError) return QVariant();
                QVariant stepVar = stepStr.isEmpty() ? QVariant() : parseExpression(stepStr);
                if (m_hasError) return QVariant();

                // Вычисляем базовое выражение
                QVariant baseValue = parseExpression(baseExpr);
                if (m_hasError) return QVariant();

                VariableType baseType = determineType(baseValue);
                QVariant result;
                QString replacementStr;

                if (baseType == Array) {
                    result = getArraySlice(baseValue.toList(), startVar, endVar, stepVar);
                } else if (baseType == String) {
                    result = getStringSlice(baseValue.toString(), startVar, endVar, stepVar);
                } else {
                    setError("Ошибка: Срез можно применять только к массиву или строке.");
                    return QVariant();
                }
                if (m_hasError) return QVariant();

                // Формируем строку для замены
                if (determineType(result) == String) {
                    replacementStr = "\"" + result.toString() + "\"";
                } else if (determineType(result) == Array) {
                    // Для массива вставляем литерал (JSON без кавычек)
                    replacementStr = QString::fromUtf8(QJsonDocument::fromVariant(result).toJson(QJsonDocument::Compact));
                } else {
                    replacementStr = result.toString();
                }
                currentExpr.replace(fullMatch, replacementStr);
                changed = true;
                qDebug() << "parseExpression: After slice replacement:" << currentExpr;
                continue;
            }
            else {
                // Обычный доступ по индексу
                QVariant baseValue = parseExpression(baseExpr);
                if (m_hasError) return QVariant();

                QVariant indexValue = parseExpression(indexExpr);
                if (m_hasError) return QVariant();

                if (determineType(indexValue) != Numeric) {
                    setError("Ошибка: Индекс для доступа должен быть числом, получено: " + indexValue.toString());
                    return QVariant();
                }

                int index = indexValue.toInt();
                VariableType baseType = determineType(baseValue);
                QVariant result;
                QString replacementStr;

                if (baseType == Array) {
                    QVariantList list = baseValue.toList();
                    if (index < 0) index = list.size() + index;
                    if (index < 0 || index >= list.size()) {
                        setError("Ошибка: Индекс массива " + QString::number(index) + " выходит за границы (размер " + QString::number(list.size()) + ").");
                        return QVariant();
                    }
                    result = list.at(index);
                } else if (baseType == String) {
                    QString str = baseValue.toString();
                    result = getStringIndexedValue(str, index);
                    if (m_hasError) return QVariant();
                } else {
                    setError("Ошибка: " + baseExpr + " не является массивом или строкой при доступе по индексу.");
                    return QVariant();
                }

                if (determineType(result) == String) {
                    replacementStr = "\"" + result.toString() + "\"";
                } else if (determineType(result) == Array) {
                    // Для массива вставляем литерал
                    replacementStr = QString::fromUtf8(QJsonDocument::fromVariant(result).toJson(QJsonDocument::Compact));
                } else {
                    replacementStr = result.toString();
                }
                currentExpr.replace(fullMatch, replacementStr);
                changed = true;
                qDebug() << "parseExpression: After array access replacement:" << currentExpr;
                continue;
            }
        }

        // --- Обработка встроенных функций (len, int, str) ---
        static QRegularExpression builtinFuncParseRegex(R"((len|int|str)\s*\(([^()]*?(?:\([^()]*\)[^()]*?)*)\))");
        QRegularExpressionMatch builtinFuncMatch = builtinFuncParseRegex.match(currentExpr);
        if (builtinFuncMatch.hasMatch()) {
            QString fullMatch = builtinFuncMatch.captured(0);
            QString funcName = builtinFuncMatch.captured(1);
            QString argsExpr = builtinFuncMatch.captured(2);

            QVariantList evaluatedArgs;
            if (!argsExpr.isEmpty()) {
                int balance = 0;
                int lastSplitPos = 0;
                for (int i = 0; i < argsExpr.length(); ++i) {
                    if (argsExpr.at(i) == '(') balance++;
                    else if (argsExpr.at(i) == ')') balance--;
                    else if (argsExpr.at(i) == ',' && balance == 0) {
                        QString argPart = argsExpr.mid(lastSplitPos, i - lastSplitPos).trimmed();
                        evaluatedArgs.append(parseExpression(argPart));
                        if (m_hasError) return QVariant();
                        lastSplitPos = i + 1;
                    }
                }
                QString lastArgPart = argsExpr.mid(lastSplitPos).trimmed();
                if (!lastArgPart.isEmpty()) {
                    evaluatedArgs.append(parseExpression(lastArgPart));
                    if (m_hasError) return QVariant();
                }
            }

            QVariant funcResult = callBuiltinFunction(funcName, evaluatedArgs);
            if (m_hasError) return QVariant();

            QString replacementStr;
            if (determineType(funcResult) == String) {
                replacementStr = "\"" + funcResult.toString() + "\"";
            } else if (determineType(funcResult) == Array) {
                replacementStr = QString::fromUtf8(QJsonDocument::fromVariant(funcResult).toJson(QJsonDocument::Compact));
            } else {
                replacementStr = funcResult.toString();
            }
            currentExpr.replace(fullMatch, replacementStr);
            changed = true;
            qDebug() << "parseExpression: After builtin func replacement:" << currentExpr;
            continue;
        }

        if (!changed) break;
    }

    if (iterationLimit <= 0) {
        setError("Ошибка: Обнаружен слишком сложный или зацикленный парсинг выражения.");
        return QVariant();
    }

    // Обработка простых литералов и переменных
    double num;
    if (canConvertToNumber(currentExpr, num)) {
        return QVariant(num);
    }
    if (currentExpr.startsWith('"') && currentExpr.endsWith('"') && currentExpr.length() >= 2) {
        return QVariant(currentExpr.mid(1, currentExpr.length() - 2));
    }
    if (currentExpr.toLower() == "true") return QVariant(true);
    if (currentExpr.toLower() == "false") return QVariant(false);

    if (peremennieMap.contains(currentExpr)) {
        return getValue(currentExpr);
    }

    qDebug() << "parseExpression: Before tokenize/evaluateTokens. Final currentExpr:" << currentExpr;
    QStringList tokens = tokenize(currentExpr);
    return evaluateTokens(tokens);
}

// ============================================================================
// БЛОК ДЕЙСТВИЯ (ПРИСВАИВАНИЕ)
// ============================================================================

void Obrabotka::deistvie(QString vvod)
{
    clearError();
    qDebug() << "deistvie input:" << vvod;
    QString trimmedVvod = vvod.trimmed();

    static QRegularExpression methodCallRegex(R"(^(.+?)\s*\.\s*(\w+)\s*\((.*)\)\s*$)");
    QRegularExpressionMatch methodCallMatch = methodCallRegex.match(trimmedVvod);
    if (methodCallMatch.hasMatch()) {
        QString targetExpr = methodCallMatch.captured(1).trimmed();
        QString methodName = methodCallMatch.captured(2).trimmed();
        QString argsExpr = methodCallMatch.captured(3).trimmed();

        QVariantList args;
        if (!argsExpr.isEmpty()) {
            QStringList argParts = argsExpr.split(',');
            for (const QString& part : argParts) {
                QVariant argValue = parseExpression(part.trimmed());
                if (m_hasError) return;
                args.append(argValue);
            }
        }

        executeMethod(targetExpr, methodName, args);
        return;
    }

    int equalsPos = trimmedVvod.indexOf('=');
    if (equalsPos == -1) {
        setError("В действии отсутствует оператор присваивания '=' или неверный вызов метода.");
        return;
    }
    QString left = trimmedVvod.left(equalsPos).trimmed();
    QString right = trimmedVvod.mid(equalsPos + 1).trimmed();
    if (left.isEmpty() || right.isEmpty()) {
        setError("Левая или правая часть присваивания не может быть пустой.");
        return;
    }
    QVariant result = parseExpression(right);
    if (m_hasError) {
        qDebug() << "deistvie: Ошибка при разборе выражения:" << m_errorMessage;
        return;
    }

    static QRegularExpression arrayAccessRegex(R"(^(\w+)\s*\[(.+)\]$)");
    QRegularExpressionMatch arrayAccessMatch = arrayAccessRegex.match(left);
    if (arrayAccessMatch.hasMatch()) {
        QString varName = arrayAccessMatch.captured(1);
        QString indexExpr = arrayAccessMatch.captured(2);

        QVariant arrayVar = getValue(varName);
        if (m_hasError) return;

        if (determineType(arrayVar) != Array) {
            setError("Переменная '" + varName + "' не является массивом. Невозможно присвоить элемент по индексу.");
            return;
        }

        QVariant indexVal = parseExpression(indexExpr);
        if (m_hasError) return;

        if (determineType(indexVal) != Numeric) {
            setError("Индекс массива должен быть числом.");
            return;
        }

        QVariantList list = arrayVar.toList();
        int index = indexVal.toInt();

        if (index < 0) {
            index = list.size() + index;
        }

        if (index < 0 || index >= list.size()) {
            setError("Индекс массива '" + QString::number(index) + "' выходит за границы. Размер массива: " + QString::number(list.size()));
            return;
        }

        list[index] = result;
        setValue(varName, QVariant(list), "array");
        qInfo() << "Присвоено элементу массива" << varName << "[" << index << "] значение:" << result;

    } else {
        setValue(left, result);
        qInfo() << "Присвоено переменной" << left << "значение:" << result;
    }
}

// ============================================================================
// УСЛОВНЫЕ ВЫРАЖЕНИЯ
// ============================================================================

bool Obrabotka::evaluateCondition(const QString& condition)
{
    clearError();
    QString cond = condition.simplified();

    if (peremennieMap.contains(cond)) {
        QVariant value = peremennieMap[cond].value;
        VariableType type = determineType(value);
        if (type == Boolean) return value.toBool();
        if (type == Numeric) return value.toDouble() != 0;
        if (type == String) return !value.toString().isEmpty();
        return false;
    }

    if (cond.toLower() == "true" || cond == "1") return true;
    if (cond.toLower() == "false" || cond == "0") return false;

    return parseCondition(cond);
}

// ============================================================================
// УСЛОВНЫЙ ОПЕРАТОР (ЕСЛИ)
// ============================================================================

void Obrabotka::usl(QString usl, QVariantList trueBranch, QVariantList falseBranch)
{
    clearError();
    bool conditionResult = evaluateCondition(usl);
    if (m_hasError) {
        qDebug() << "Ошибка при проверке условия if";
        return;
    }
    if (conditionResult) {
        qDebug() << "Условие ИСТИНА, выполняем true ветку";
        vipolnenie(trueBranch);
    } else {
        qDebug() << "Условие ЛОЖЬ, выполняем false ветку";
        vipolnenie(falseBranch);
    }
}

// ============================================================================
// ПАРСИНГ И ВЫЧИСЛЕНИЕ УСЛОВИЙ
// ============================================================================

bool Obrabotka::parseCondition(const QString& cond)
{
    clearError();
    QString condition = cond.simplified();
    condition.replace(" ", "");

    qDebug() << "Парсим условие:" << condition;
    QString processedCondition = condition;
    processedCondition.replace(QRegularExpression("\\bи\\b"), " && ");
    processedCondition.replace(QRegularExpression("\\bили\\b"), " || ");
    processedCondition.replace(QRegularExpression("\\bне\\b"), " ! ");
    processedCondition = processedCondition.simplified();
    qDebug() << "Обработанное условие:" << processedCondition;

    if (processedCondition.contains("&&") || processedCondition.contains("||") || processedCondition.contains("!") ||
        processedCondition.contains("(") || processedCondition.contains(")")) {
        QStringList tokens;
        QString currentToken;
        bool inString = false;

        for (int i = 0; i < processedCondition.length(); i++) {
            QChar ch = processedCondition[i];
            if (ch == '"') {
                if (inString) {
                    currentToken.append(ch);
                    tokens.append(currentToken);
                    currentToken.clear();
                    inString = false;
                } else {
                    if (!currentToken.isEmpty()) {
                        tokens.append(currentToken);
                        currentToken.clear();
                    }
                    currentToken.append(ch);
                    inString = true;
                }
            } else if (inString) {
                currentToken.append(ch);
            } else if (ch == '&' || ch == '|' || ch == '!' || ch == '(' || ch == ')') {
                if (!currentToken.isEmpty()) {
                    tokens.append(currentToken);
                    currentToken.clear();
                }
                if (ch == '&' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '&') {
                    tokens.append("&&");
                    i++;
                } else if (ch == '|' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '|') {
                    tokens.append("||");
                    i++;
                } else if (ch == '!') {
                    tokens.append("!");
                } else {
                    tokens.append(QString(ch));
                }
            } else {
                currentToken.append(ch);
            }
        }

        if (!currentToken.isEmpty()) {
            tokens.append(currentToken);
        }

        qDebug() << "Токены:" << tokens;
        return evaluateComplexCondition(tokens);
    } else {
        return evaluateSimpleCondition(processedCondition);
    }
}

bool Obrabotka::evaluateSimpleCondition(const QString& cond)
{
    QString condition = cond;

    if (condition == "1" || condition.toLower() == "true") return true;
    if (condition == "0" || condition.toLower() == "false") return false;

    QVector<QString> operators = { ">=", "<=", "!=", "==", ">", "<" };
    QString foundOp;
    for (const QString& op : operators) {
        if (condition.contains(op)) {
            foundOp = op;
            break;
        }
    }

    if (foundOp.isEmpty()) {
        QVariant value = getValue(condition);
        VariableType type = determineType(value);
        if (type == Boolean) return value.toBool();
        if (type == Numeric) return value.toDouble() != 0;
        if (type == String) return !value.toString().isEmpty();
        return false;
    }

    QStringList parts = condition.split(foundOp);
    if (parts.size() != 2) return false;
    QVariant leftVal = parseExpression(parts[0]);
    QVariant rightVal = parseExpression(parts[1]);
    if (m_hasError) return false;
    return compareValues(leftVal, rightVal, foundOp);
}

bool Obrabotka::evaluateComplexCondition(QStringList& tokens)
{
    qDebug() << "Вычисляем сложное условие с токенами:" << tokens;

    for (int i = 0; i < tokens.size(); ) {
        if (tokens[i] == "!") {
            if (i + 1 >= tokens.size()) return false;
            bool operandValue;
            if (tokens[i+1] == "(") {
                int bracketCount = 1;
                int j = i + 2;
                while (j < tokens.size() && bracketCount > 0) {
                    if (tokens[j] == "(") bracketCount++;
                    else if (tokens[j] == ")") bracketCount--;
                    j++;
                }
                QStringList subTokens;
                for (int k = i + 2; k < j - 1; k++) {
                    subTokens.append(tokens[k]);
                }
                operandValue = evaluateComplexCondition(subTokens);
            } else {
                operandValue = evaluateSimpleCondition(tokens[i+1]);
            }
            if (m_hasError) return false;
            tokens[i] = (!operandValue) ? "1" : "0";
            tokens.removeAt(i+1);
        } else {
            i++;
        }
    }

    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) return false;
            int start = bracketStack.top();
            bracketStack.pop();
            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }
            bool bracketResult = evaluateComplexCondition(subTokens);
            if (m_hasError) return false;
            tokens[start] = bracketResult ? "1" : "0";
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }
    if (!bracketStack.empty()) return false;

    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] != "&&" && tokens[i] != "||" && tokens[i] != "(" && tokens[i] != ")") {
            bool value = evaluateSimpleCondition(tokens[i]);
            if (m_hasError) return false;
            tokens[i] = value ? "1" : "0";
        }
    }

    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "&&") {
            bool leftVal = (tokens[i-1] == "1");
            bool rightVal = (tokens[i+1] == "1");
            bool result = leftVal && rightVal;
            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "||") {
            bool leftVal = (tokens[i-1] == "1");
            bool rightVal = (tokens[i+1] == "1");
            bool result = leftVal || rightVal;
            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    if (tokens.size() != 1) return false;
    return tokens[0] == "1";
}

// ============================================================================
// ЦИКЛ С ПАРАМЕТРОМ (СЧЕТЧИК)
// ============================================================================

void Obrabotka::schetchik(const QString& counterExpr, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла for:" << counterExpr;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    QString varName;
    int startVal, endVal, stepVal;
    if (!parseCounter(counterExpr, varName, startVal, endVal, stepVal)) {
        return;
    }

    qDebug() << "Цикл for:" << varName << "от" << startVal << "до" << endVal << "шаг" << stepVal;
    if (stepVal == 0) return;

    if (stepVal > 0) {
        for (int i = startVal; i <= endVal; i += stepVal) {
            setValue(varName, QVariant(i), "int");
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
                if (m_hasError) return;
            }
        }
    } else {
        for (int i = startVal; i >= endVal; i += stepVal) {
            setValue(varName, QVariant(i), "int");
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
                if (m_hasError) return;
            }
        }
    }

    qDebug() << "Цикл for завершен";
}

bool Obrabotka::parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal)
{
    QString expression = expr.simplified();
    expression.replace(" ", "");

    int toIndex = expression.indexOf("to");
    if (toIndex == -1) toIndex = expression.indexOf("до");
    if (toIndex == -1) return false;

    int equalsIndex = expression.indexOf("=");
    if (equalsIndex == -1 || equalsIndex >= toIndex) return false;

    varName = expression.left(equalsIndex);
    QString startStr = expression.mid(equalsIndex + 1, toIndex - equalsIndex - 1);

    int stepIndex = expression.indexOf("step", toIndex + 2, Qt::CaseInsensitive);
    if (stepIndex == -1) stepIndex = expression.indexOf("шаг", toIndex + 2, Qt::CaseInsensitive);

    QString endStr, stepStr;
    if (stepIndex != -1) {
        endStr = expression.mid(toIndex + 2, stepIndex - toIndex - 2);
        stepStr = expression.mid(stepIndex + (expression.mid(stepIndex, 1) == "s" ? 4 : 3));
    } else {
        endStr = expression.mid(toIndex + 2);
        stepStr = "1";
    }

    startVal = parseExpression(startStr).toInt();
    endVal = parseExpression(endStr).toInt();
    stepVal = parseExpression(stepStr).toInt();

    qDebug() << "Парсинг счетчика:" << varName << "=" << startVal << "to" << endVal << "step" << stepVal;
    return true;
}

// ============================================================================
// ЦИКЛ С ПРЕДУСЛОВИЕМ (WHILE)
// ============================================================================

void Obrabotka::predusl(const QString& condition, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла while (предусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    while (evaluateCondition(condition)) {
        if (m_hasError) {
            qDebug() << "Ошибка при проверке условия в цикле while";
            return;
        }
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qDebug() << "Превышено максимальное количество итераций в цикле while";
            return;
        }
        qDebug() << "Итерация while:" << iteration;
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
            if (m_hasError) {
                qDebug() << "Ошибка в теле цикла while";
                return;
            }
        } else {
            qDebug() << "Тело цикла while пустое!";
        }
    }

    qDebug() << "Цикл while завершен, итераций:" << iteration;
}

// ============================================================================
// ЦИКЛ С ПОСТУСЛОВИЕМ (DO-WHILE)
// ============================================================================

void Obrabotka::postusl(const QString& condition, QVariantList loopBody)
{
    clearError();
    qDebug() << "Запуск цикла do-while (постусловие):" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    do {
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qDebug() << "Превышено максимальное количество итераций в цикле do-while";
            return;
        }
        qDebug() << "Итерация do-while:" << iteration;
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
            if (m_hasError) {
                qDebug() << "Ошибка в теле цикла do-while";
                return;
            }
        } else {
            qDebug() << "Тело цикла do-while пустое!";
        }

        bool conditionResult = evaluateCondition(condition);
        qDebug() << "Проверка условия после итерации" << iteration << ":" << condition << "=" << conditionResult;
        if (m_hasError) {
            qDebug() << "Ошибка при проверке условия в цикле do-while";
            return;
        }
        if (!conditionResult) {
            qDebug() << "Условие ложно, завершаем цикл do-while";
            break;
        }
    } while (true);

    qDebug() << "Цикл do-while завершен, итераций:" << iteration;
}

// ============================================================================
// ОСНОВНОЙ ИНТЕРПРЕТАТОР АЛГОРИТМА
// ============================================================================

void Obrabotka::vipolnenie(QVariantList algorithm)
{
    clearError();
    qDebug() << ">>> ВЫПОЛНЕНИЕ АЛГОРИТМА (размер:" << algorithm.size() << ")";

    for (int i = 0; i < algorithm.size(); ++i) {
        if (m_hasError) {
            qDebug() << "Выполнение прервано из-за ошибки";
            return;
        }

        QVariant item = algorithm[i];
        qDebug() << "Обрабатываем блок" << i << ":" << item;

        if (!item.canConvert<QVariantMap>()) {
            qDebug() << "Блок не может быть преобразован в QVariantMap";
            continue;
        }

        QVariantMap block = item.value<QVariantMap>();
        qDebug() << "Распакованный блок:" << block;

        QString type = block["type"].toString();
        QString content = block["input"].toString();
        qDebug() << "Тип:" << type << "| Содержимое:" << content;

        if (type == "ввод") {
            vvod(content);
        } else if (type == "вывод") {
            vivodim_functionod(content);
        } else if (type == "действие") {
            deistvie(content);
        } else if (type == "усл") {
            QVariantList trueBranch = block["trueBranch"].value<QVariantList>();
            QVariantList falseBranch = block["falseBranch"].value<QVariantList>();
            qDebug() << "Условие - true ветка:" << trueBranch.size() << "блоков, false ветка:" << falseBranch.size() << "блоков";
            usl(content, trueBranch, falseBranch);
        } else if (type == "счетчик") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
            qDebug() << "Счетчик - тело цикла:" << loopBody.size() << "блоков";
            schetchik(content, loopBody);
        } else if (type == "предусл") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
            qDebug() << "Предусловие - тело цикла:" << loopBody.size() << "блоков";
            predusl(content, loopBody);
        } else if (type == "постусл") {
            QVariantList loopBody = block["loopBody"].value<QVariantList>();
            qDebug() << "Постусловие - тело цикла:" << loopBody.size() << "блоков";
            postusl(content, loopBody);
        } else {
            qDebug() << "Неизвестный тип блока:" << type;
        }

        if (m_hasError) {
            qDebug() << "Ошибка в блоке" << i << ", тип:" << type;
            return;
        }
    }

    qDebug() << "<<< ЗАВЕРШЕНИЕ ВЫПОЛНЕНИЯ АЛГОРИТМА";
}

// ============================================================================
// ОТЛАДКА: СОХРАНЕНИЕ СОСТОЯНИЙ
// ============================================================================

void Obrabotka::saveDebugState(int finishedBlockId)
{
    m_debugHistory.push(convertToQmlVariantMap());
    m_blockIdHistory.push(finishedBlockId);
    m_currentHistoryIndex = m_debugHistory.size() - 1;
    qDebug() << "Сохранено состояние. Индекс истории:" << m_currentHistoryIndex
             << "ID завершенного блока:" << finishedBlockId;
}

bool Obrabotka::hasMoreBlocks()
{
    return m_currentDebugBlockId != -1;
}

void Obrabotka::sendCurrentState(int highlightId)
{
    QVariantMap currentState = convertToQmlVariantMap();
    emit debugging_peremennie(currentState);
    emit highlightBlock(highlightId);
    emit debugHistoryChanged(m_currentHistoryIndex > 0, hasMoreBlocks());
}

// ============================================================================
// ОТЛАДКА: ВЫПОЛНЕНИЕ ОДИНОЧНОГО БЛОКА
// ============================================================================

void Obrabotka::executeDebugBlock(const QVariantMap& block)
{
    if (block.isEmpty()) {
        return;
    }

    QString type = block["type"].toString();
    QString content = block["input"].toString();

    if (type == "ввод") {
        vvod(content);
    } else if (type == "вывод") {
        vivodim_functionod(content);
    } else if (type == "действие") {
        deistvie(content);
    }
}

// ============================================================================
// ОТЛАДКА: ОЧИСТКА СОСТОЯНИЯ
// ============================================================================

void Obrabotka::internal_cleanup()
{
    m_debugging = false;
    m_currentDebugBlockId = -1;
    m_debugHistory.clear();
    m_blockIdHistory.clear();
    m_loopInitialized.clear();
    m_currentHistoryIndex = -1;
    m_algorithmStack.clear();
    m_debugLoopStack.clear();
    peremennieMap.clear();
    clearError();
}

// ============================================================================
// ОТЛАДКА: ПЛОСКАЯ СТРУКТУРА АЛГОРИТМА
// ============================================================================

void Obrabotka::flattenAlgorithm(const QVariantList& algorithm, int& nextId)
{
    for (int i = 0; i < algorithm.size(); ++i) {
        const QVariantMap& block = algorithm[i].value<QVariantMap>();
        if (!block.contains("uniqueId")) {
            qWarning() << "flattenAlgorithm: Пропускаем блок без uniqueId:" << block;
            continue;
        }

        int blockId = block["uniqueId"].toInt();
        m_blockMap.insert(blockId, block);

        int nextSequentialId = (i + 1 < algorithm.size())
                                   ? algorithm[i + 1].value<QVariantMap>()["uniqueId"].toInt()
                                   : nextId;

        m_nextBlockIdMap.insert(blockId, nextSequentialId);

        QString type = block["type"].toString();
        if (type == "усл") {
            flattenAlgorithm(block["trueBranch"].value<QVariantList>(), nextSequentialId);
            flattenAlgorithm(block["falseBranch"].value<QVariantList>(), nextSequentialId);
        } else if (type == "счетчик" || type == "предусл" || type == "постусл") {
            flattenAlgorithm(block["loopBody"].value<QVariantList>(), blockId);
        }
    }
}

// ============================================================================
// ОТЛАДКА: ПОИСК СЛЕДУЮЩЕГО БЛОКА
// ============================================================================

int Obrabotka::findNextBlockId(int currentId, bool& wasLoop)
{
    wasLoop = false;
    if (!m_blockMap.contains(currentId)) return -1;

    QVariantMap currentBlock = m_blockMap.value(currentId);
    QString type = currentBlock["type"].toString();
    QString content = currentBlock["input"].toString();
    int nextSequentialId = m_nextBlockIdMap.value(currentId, -1);

    if (type == "усл") {
        return evaluateCondition(content)
        ? (currentBlock["trueBranch"].value<QVariantList>().isEmpty()
               ? nextSequentialId
               : currentBlock["trueBranch"].value<QVariantList>().first().value<QVariantMap>()["uniqueId"].toInt())
        : (currentBlock["falseBranch"].value<QVariantList>().isEmpty()
               ? nextSequentialId
               : currentBlock["falseBranch"].value<QVariantList>().first().value<QVariantMap>()["uniqueId"].toInt());
    } else if (type == "счетчик") {
        wasLoop = true;
        QString varName;
        int startVal, endVal, stepVal;
        parseCounter(content, varName, startVal, endVal, stepVal);

        if (!m_loopInitialized.contains(currentId)) {
            setValue(varName, startVal, "int");
            m_loopInitialized[currentId] = true;
        } else {
            setValue(varName, getValue(varName).toInt() + stepVal, "int");
        }

        if ((stepVal >= 0) ? (getValue(varName).toInt() <= endVal) : (getValue(varName).toInt() >= endVal)) {
            const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
            return loopBody.isEmpty()
                       ? currentId
                       : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
        } else {
            m_loopInitialized.remove(currentId);
            return nextSequentialId;
        }
    } else if (type == "предусл") {
        wasLoop = true;
        if (evaluateCondition(content)) {
            const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
            return loopBody.isEmpty()
                       ? currentId
                       : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
        } else {
            return nextSequentialId;
        }
    } else if (type == "постусл") {
        wasLoop = true;
        const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
        return loopBody.isEmpty()
                   ? currentId
                   : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
    } else {
        return nextSequentialId;
    }
}

// ============================================================================
// ОТЛАДКА: ЗАПУСК И УПРАВЛЕНИЕ
// ============================================================================

void Obrabotka::startDebugging(QVariantList algorithm, int startBlockId)
{
    QVariantList syntaxErrors = checkAlgorithmSyntax(algorithm);
    if (!syntaxErrors.isEmpty()) {
        emit syntaxErrorsOccurred(syntaxErrors);
        return;
    }

    internal_cleanup();
    m_currentAlgorithm = algorithm;
    m_blockMap.clear();
    m_nextBlockIdMap.clear();

    int endOfMain = -1;
    flattenAlgorithm(m_currentAlgorithm, endOfMain);
    m_debugging = true;

    int firstBlockId = m_currentAlgorithm.isEmpty()
                           ? -1
                           : m_currentAlgorithm.first().value<QVariantMap>()["uniqueId"].toInt();

    if (startBlockId != -1 && m_blockMap.contains(startBlockId) && startBlockId != firstBlockId) {
        qDebug() << "Бесшумный запуск до блока" << startBlockId;
        int blockToRun = firstBlockId;
        int runLimit = 10000;

        while (blockToRun != -1 && blockToRun != startBlockId && runLimit-- > 0) {
            if (m_hasError) {
                stopDebugging();
                return;
            }
            QVariantMap block = m_blockMap.value(blockToRun);
            QString type = block["type"].toString();
            if (type != "усл" && type != "счетчик" && type != "предусл" && type != "постусл") {
                executeDebugBlock(block);
            }
            bool wasLoopUnused;
            blockToRun = findNextBlockId(blockToRun, wasLoopUnused);
        }

        if (runLimit <= 0) {
            setError("Превышен лимит итераций при подготовке к отладке. Возможен бесконечный цикл.");
            stopDebugging();
            return;
        }
    }

    saveDebugState(-1);

    if (startBlockId != -1 && m_blockMap.contains(startBlockId)) {
        m_currentDebugBlockId = startBlockId;
    } else {
        m_currentDebugBlockId = firstBlockId;
    }

    sendCurrentState(-1);
    qDebug() << ">>> НАЧАЛО ОТЛАДКИ (карта блоков:" << m_blockMap.size() << "шт.). Стартовый блок:" << m_currentDebugBlockId;
}

// ============================================================================
// ОТЛАДКА: ПОШАГОВОЕ ВЫПОЛНЕНИЕ
// ============================================================================

void Obrabotka::debugStep()
{
    if (!m_debugging || m_currentDebugBlockId == -1) {
        if (m_debugging) {
            stopDebugging();
        }
        return;
    }

    clearError();
    int idOfBlockToExecute = m_currentDebugBlockId;
    QVariantMap currentBlock = m_blockMap.value(idOfBlockToExecute);
    QString type = currentBlock["type"].toString();

    if (type != "усл" && type != "счетчик" && type != "предусл" && type != "постусл") {
        executeDebugBlock(currentBlock);
    }

    bool wasLoop = false;
    int nextBlockId = findNextBlockId(idOfBlockToExecute, wasLoop);

    if (type == "постусл" && !wasLoop) {
        bool isLoopingBack = (m_blockIdHistory.size() > 1 &&
                              m_nextBlockIdMap.value(m_blockIdHistory.top(), -1) == idOfBlockToExecute);
        if (isLoopingBack) {
            if (evaluateCondition(currentBlock["input"].toString())) {
                const QVariantList& loopBody = currentBlock["loopBody"].value<QVariantList>();
                nextBlockId = loopBody.isEmpty()
                                  ? idOfBlockToExecute
                                  : loopBody.first().value<QVariantMap>()["uniqueId"].toInt();
            } else {
                nextBlockId = m_nextBlockIdMap.value(idOfBlockToExecute, -1);
            }
        }
    }

    if (m_hasError) {
        stopDebugging();
        return;
    }

    saveDebugState(idOfBlockToExecute);
    m_currentDebugBlockId = nextBlockId;
    sendCurrentState(idOfBlockToExecute);
}

// ============================================================================
// ОТЛАДКА: ВОЗВРАТ НА ШАГ НАЗАД
// ============================================================================

void Obrabotka::debugStepBack()
{
    if (m_debugHistory.size() < 2) return;

    m_debugHistory.pop();
    int undoneBlockId = m_blockIdHistory.top();
    m_blockIdHistory.pop();
    restoreStateFromVariantMap(m_debugHistory.top());
    int blockIdToShow = m_blockIdHistory.top();

    m_currentDebugBlockId = undoneBlockId;
    m_loopInitialized.clear();
    m_currentHistoryIndex--;

    sendCurrentState(blockIdToShow);
}

// ============================================================================
// ОТЛАДКА: ЗАВЕРШЕНИЕ
// ============================================================================

void Obrabotka::stopDebugging()
{
    internal_cleanup();
    emit debugging_peremennie(QVariantMap());
    emit highlightBlock(-1);
    emit debugHistoryChanged(false, false);
    emit debugFinished();
}

// ============================================================================
// ОСНОВНОЙ ЗАПУСК АЛГОРИТМА
// ============================================================================

void Obrabotka::myPriem(QVariantList algoritm)
{
    clearError();
    QVariantList syntaxErrors = checkAlgorithmSyntax(algoritm);
    if (!syntaxErrors.isEmpty()) {
        emit syntaxErrorsOccurred(syntaxErrors);
        return;
    }
    vipolnenie(algoritm);
    peremennieMap.clear();
}

// ============================================================================
// РАБОТА С ФАЙЛАМИ
// ============================================================================

QString Obrabotka::currentFilePath() const
{
    return m_currentFilePath;
}

void Obrabotka::setCurrentFilePath(const QString &filePath)
{
    if (m_currentFilePath != filePath) {
        m_currentFilePath = filePath;
        emit currentFilePathChanged();
    }
}

void Obrabotka::createNewInstance(const QUrl &filePath)
{
    QProcess::startDetached(QCoreApplication::applicationFilePath(), QStringList() << filePath.toLocalFile());
    QCoreApplication::quit();
}

bool Obrabotka::saveAlgorithmToFile(const QVariantList& algorithm, const QUrl& filePath)
{
    QString localPath = filePath.toLocalFile();
    if (localPath.isEmpty()) {
        emit errorOccurred("Неверный путь к файлу.");
        return false;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Could not open file for writing:" << localPath;
        emit errorOccurred("Не удалось открыть файл для записи: " + localPath);
        return false;
    }

    QJsonDocument doc = QJsonDocument::fromVariant(QVariant(algorithm));
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    setCurrentFilePath(localPath);
    emit fileSaved(localPath);
    return true;
}

QVariantList Obrabotka::loadAlgorithmFromFile(const QUrl& filePath)
{
    QString localPath = filePath.toLocalFile();
    QVariantList result;

    if (localPath.isEmpty()) {
        emit errorOccurred("Неверный путь к файлу.");
        return result;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit errorOccurred("Не удалось открыть файл для чтения: " + localPath);
        return result;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        QString errorMsg = "Ошибка при разборе JSON: " + parseError.errorString();
        emit errorOccurred(errorMsg);
        return result;
    }

    if (!doc.isArray()) {
        QString errorMsg = "Файл не содержит корректную структуру алгоритма";
        emit errorOccurred(errorMsg);
        return result;
    }

    QJsonArray jsonArray = doc.array();
    result = jsonArray.toVariantList();
    emit algorithmLoaded(result);
    return result;
}

// ============================================================================
// РАБОТА С НАСТРОЙКАМИ
// ============================================================================

void Obrabotka::saveSettings(const QVariantMap &settings)
{
    QSettings qSettings;
    for (auto it = settings.constBegin(); it != settings.constEnd(); ++it) {
        qSettings.setValue(it.key(), it.value());
    }
    qSettings.sync();
    qDebug() << "Настройки сохранены с помощью QSettings.";
}

QVariantMap Obrabotka::loadSettings()
{
    QSettings qSettings;
    QVariantMap loadedSettings;
    QStringList keys = qSettings.allKeys();
    for (const QString &key : keys) {
        loadedSettings[key] = qSettings.value(key);
    }
    qDebug() << "Настройки загружены с помощью QSettings.";
    return loadedSettings;
}

// ============================================================================
// ПРОВЕРКА СИНТАКСИСА АЛГОРИТМА
// ============================================================================

QVariantList Obrabotka::checkAlgorithmSyntax(const QVariantList& algorithm)
{
    QVariantList allErrors;

    for (const QVariant& blockVariant : algorithm) {
        if (!blockVariant.canConvert<QVariantMap>()) {
            addSyntaxError("Некорректный формат блока алгоритма.", -1, allErrors);
            continue;
        }

        QVariantMap block = blockVariant.toMap();
        QString type = block["type"].toString();
        QString content = block["input"].toString();
        int blockId = block["uniqueId"].toInt();

        if (type == "действие") {
            QString trimmedContent = content.trimmed();
            int equalsPos = trimmedContent.indexOf('=');
            if (equalsPos == -1) {
                static QRegularExpression methodCallRegex(R"(^(.+?)\s*\.\s*(\w+)\s*\((.*)\)\s*$)");
                if (!methodCallRegex.match(trimmedContent).hasMatch()) {
                    addSyntaxError("В действии отсутствует оператор присваивания '=' или неверный вызов метода.", blockId, allErrors);
                }
            } else {
                QString left = trimmedContent.left(equalsPos).trimmed();
                QString right = trimmedContent.mid(equalsPos + 1).trimmed();
                if (left.isEmpty()) {
                    addSyntaxError("Левая часть присваивания не может быть пустой.", blockId, allErrors);
                }
                if (right.isEmpty()) {
                    addSyntaxError("Правая часть присваивания не может быть пустой.", blockId, allErrors);
                } else {
                    validateExpressionSyntax(right, blockId, allErrors, false);
                }
            }
        } else if (type == "усл" || type == "предусл" || type == "постусл") {
            validateExpressionSyntax(content, blockId, allErrors, true);
        } else if (type == "счетчик") {
            QRegularExpression counterParseRegex(R"(^\s*(\w+)\s*=\s*(.+)\s+(?:to|до)\s+(.+)\s+(?:step|шаг)\s*(.+)\s*$)");
            QRegularExpressionMatch counterMatch = counterParseRegex.match(content);
            if (!counterMatch.hasMatch()) {
                addSyntaxError("Некорректный формат выражения счетчика. Ожидается: 'переменная = начало до конец шаг шаг'", blockId, allErrors);
            } else {
                validateExpressionSyntax(counterMatch.captured(2), blockId, allErrors, false);
                validateExpressionSyntax(counterMatch.captured(3), blockId, allErrors, false);
                validateExpressionSyntax(counterMatch.captured(4), blockId, allErrors, false);
            }
        }

        if (block.contains("trueBranch")) {
            QVariantList subBlocks = block["trueBranch"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
        if (block.contains("falseBranch")) {
            QVariantList subBlocks = block["falseBranch"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
        if (block.contains("loopBody")) {
            QVariantList subBlocks = block["loopBody"].value<QVariantList>();
            QVariantList subErrors = checkAlgorithmSyntax(subBlocks);
            for (const QVariant& err : subErrors) {
                allErrors.append(err);
            }
        }
    }

    return allErrors;
}
