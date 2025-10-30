#include "obrabotka.h"
#include <QQmlEngine>
#include <QDebug>
#include <QString>
#include <iostream>
#include <QRegularExpression>
#include <stack>
#include <algorithm>

Obrabotka::Obrabotka(QObject *parent) : QObject(parent) {}

// область с функциями под блоки алгоритма

//блок ввода
int Obrabotka::requestUserInput()
{
    qDebug() << "C++: Запрашиваем ввод пользователя";
    m_waitingForInput = true;
    emit needUserInput(); // Отправляем сигнал в QML
    m_loop.exec();
    return 1;
}

// Слот для получения результата из QML
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

void Obrabotka::vvod(const QString& variableName) {
    // Шаг 1: Запрос ввода
    if (!requestUserInput()) {
        qDebug() << "0";
        qDebug() << "ошибка!!!";
        return;
    }

    qDebug() << "1";

    // Шаг 2: Получено значение
    QString inputValue = vvod_peremennich_polsovatela;

    // Шаг 3: Поиск переменной в первом столбце
    bool found = false;
    for (auto& row : peremennie) {
        if (row.size() >= 2 && row[0] == variableName) {
            row[1] = inputValue; // обновляем значение
            found = true;
            break;
        }
    }

    // Если не найдена — добавляем новую запись
    if (!found) {
        std::vector<QString> newRow;
        newRow.push_back(variableName);
        newRow.push_back(inputValue);
        peremennie.push_back(newRow);
    }

    // Шаг 4: Выводим весь вектор
    qDebug() << "=== Состояние переменных ===";
    for (const auto& row : peremennie) {
        if (row.size() >= 2) {
            qDebug() << "Переменная:" << row[0] << "| Значение:" << row[1];
        }
    }
    qDebug() << "=============================";
}

// ответ
void Obrabotka::vivodim_functionod(QString peremen){
    qDebug() << "запуск вывода!";
    for(int i = 0; i < peremennie.size(); i++) {
        if (peremennie[i].size() >= 2) {
            if (peremennie[i][0] == peremen) {
                emit vivod(peremennie[i][1]);
                break;
            }
        }
    }
}

//действие
int Obrabotka::getValue(const QString& name) {
    // Проверяем, есть ли переменная
    for (const auto& row : peremennie) {
        if (row.size() >= 2 && row[0] == name) {
            bool ok;
            int value = row[1].toInt(&ok);
            if (ok) return value;
            return 0;
        }
    }

    // Если переменной нет - создаем со значением 0
    qDebug() << "Переменная" << name << "не найдена, создаем со значением 0";
    std::vector<QString> newRow;
    newRow.push_back(name);
    newRow.push_back("0");
    peremennie.push_back(newRow);

    return 0;
}

void Obrabotka::setValue(const QString& name, int value) {
    for (auto& row : peremennie) {
        if (row.size() >= 2 && row[0] == name) {
            row[1] = QString::number(value);
            return;
        }
    }
    // Если переменной нет, создаем новую
    std::vector<QString> newRow;
    newRow.push_back(name);
    newRow.push_back(QString::number(value));
    peremennie.push_back(newRow);
}

QStringList Obrabotka::tokenize(const QString& expr) {
    QStringList tokens;
    QString currentToken;

    for (QChar ch : expr) {
        if (ch.isSpace()) {
            continue;
        }

        if (ch == '(' || ch == ')' || ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '%') {
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

int Obrabotka::evaluateTokens(QStringList& tokens) {
    // Обработка скобок
    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                qCritical() << "Ошибка: Непарная закрывающая скобка";
                return 0;
            }

            int start = bracketStack.top();
            bracketStack.pop();

            // Вычисляем выражение внутри скобок
            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }

            int bracketResult = evaluateTokens(subTokens);

            // Заменяем скобки и их содержимое на результат
            tokens[start] = QString::number(bracketResult);
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }

    if (!bracketStack.empty()) {
        qCritical() << "Ошибка: Непарная открывающая скобка";
        return 0;
    }

    // Заменяем переменные на их значения
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] != "+" && tokens[i] != "-" && tokens[i] != "*" &&
            tokens[i] != "/" && tokens[i] != "%" && tokens[i] != "(" && tokens[i] != ")") {
            bool isNumber;
            tokens[i].toInt(&isNumber);
            if (!isNumber) {
                tokens[i] = QString::number(getValue(tokens[i]));
            }
        }
    }

    // Вычисляем операции *, /, %
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "*" || tokens[i] == "/" || tokens[i] == "%") {
            int leftVal = tokens[i-1].toInt();
            int rightVal = tokens[i+1].toInt();
            int result;

            if (tokens[i] == "*") {
                result = leftVal * rightVal;
            } else if (tokens[i] == "/") {
                if (rightVal == 0) {
                    qCritical() << "Ошибка: Деление на ноль";
                    return 0;
                }
                result = leftVal / rightVal;
            } else {
                if (rightVal == 0) {
                    qCritical() << "Ошибка: Деление на ноль при взятии остатка";
                    return 0;
                }
                result = leftVal % rightVal;
            }

            tokens[i-1] = QString::number(result);
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    // Вычисляем операции +, -
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "+" || tokens[i] == "-") {
            int leftVal = tokens[i-1].toInt();
            int rightVal = tokens[i+1].toInt();
            int result = (tokens[i] == "+") ? leftVal + rightVal : leftVal - rightVal;

            tokens[i-1] = QString::number(result);
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    if (tokens.size() != 1) {
        qCritical() << "Ошибка: Неверное выражение";
        return 0;
    }

    return tokens[0].toInt();
}

int Obrabotka::parseExpression(const QString& expr) {
    QStringList tokens = tokenize(expr);
    return evaluateTokens(tokens);
}

void Obrabotka::deistvie(QString vvod) {
    // Удаляем все пробелы
    vvod.remove(QRegularExpression("\\s+"));

    // Разделяем строку на левую и правую части относительно '='
    int equalsPos = vvod.indexOf('=');
    if (equalsPos == -1) {
        qCritical() << "Ошибка: Отсутствует знак присваивания '='";
        return;
    }

    QString left = vvod.left(equalsPos);
    QString right = vvod.mid(equalsPos + 1);

    if (left.isEmpty()) {
        qCritical() << "Ошибка: Отсутствует имя переменной";
        return;
    }

    if (right.isEmpty()) {
        qCritical() << "Ошибка: Отсутствует выражение после '='";
        return;
    }

    // Парсим и вычисляем выражение
    int result = parseExpression(right);

    // Сохраняем результат
    setValue(left, result);
    qInfo() << "Присвоено переменной" << left << "значение:" << result;
}

// условие

void Obrabotka::usl(QString usl, QVariantList trueBranch, QVariantList falseBranch) {
    if (parseCondition(usl)) {
        qDebug() << "Условие ИСТИНА, выполняем true ветку";
        vipolnenie(trueBranch);
    } else {
        qDebug() << "Условие ЛОЖЬ, выполняем false ветку";
        vipolnenie(falseBranch);
    }
}

bool Obrabotka::parseCondition(const QString& cond) {
    QString condition = cond.simplified();
    condition.replace(" ", "");

    qDebug() << "Парсим условие:" << condition;

    // Заменяем русские логические операторы на английские с пробелами
    QString processedCondition = condition;

    // Заменяем русские операторы на английские с пробелами для правильной токенизации
    processedCondition.replace(QRegularExpression("\\bии\\b"), " && ");
    processedCondition.replace(QRegularExpression("\\bили\\b"), " || ");
    processedCondition.replace(QRegularExpression("\\bи\\b"), " && ");

    // Убираем лишние пробелы и нормализуем
    processedCondition = processedCondition.simplified();

    qDebug() << "Обработанное условие:" << processedCondition;

    // Проверяем, есть ли логические операторы
    if (processedCondition.contains("&&") || processedCondition.contains("||") ||
        processedCondition.contains("(") || processedCondition.contains(")")) {
        // Токенизация для сложных условий
        QStringList tokens;
        QString currentToken;

        for (int i = 0; i < processedCondition.length(); i++) {
            QChar ch = processedCondition[i];

            if (ch == '&' || ch == '|' || ch == '(' || ch == ')') {
                if (!currentToken.isEmpty()) {
                    tokens.append(currentToken);
                    currentToken.clear();
                }
                if (ch == '&' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '&') {
                    tokens.append("&&");
                    i++; // Пропускаем второй символ
                } else if (ch == '|' && i + 1 < processedCondition.length() && processedCondition[i + 1] == '|') {
                    tokens.append("||");
                    i++; // Пропускаем второй символ
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

bool Obrabotka::evaluateSimpleCondition(const QString& cond) {
    QString condition = cond;

    // Сначала проверяем на логические значения
    if (condition == "1" || condition.toLower() == "true" || condition.toLower() == "истина") {
        return true;
    }
    if (condition == "0" || condition.toLower() == "false" || condition.toLower() == "ложь") {
        return false;
    }

    QVector<QString> operators = {">=", "<=", "!=", "==", ">", "<"};
    QString foundOp;

    for (const QString& op : operators) {
        if (condition.contains(op)) {
            foundOp = op;
            break;
        }
    }

    if (foundOp.isEmpty()) {
        qWarning() << "Неизвестный оператор в условии:" << condition;
        return false;
    }

    QStringList parts = condition.split(foundOp);
    if (parts.size() != 2) {
        qWarning() << "Неверный формат условия:" << condition;
        return false;
    }

    int leftVal = parseExpression(parts[0]);
    int rightVal = parseExpression(parts[1]);

    if (foundOp == ">") return leftVal > rightVal;
    if (foundOp == "<") return leftVal < rightVal;
    if (foundOp == ">=") return leftVal >= rightVal;
    if (foundOp == "<=") return leftVal <= rightVal;
    if (foundOp == "==") return leftVal == rightVal;
    if (foundOp == "!=") return leftVal != rightVal;

    return false;
}

bool Obrabotka::evaluateComplexCondition(QStringList& tokens) {
    qDebug() << "Вычисляем сложное условие с токенами:" << tokens;

    // Обработка скобок
    std::stack<int> bracketStack;
    for (int i = 0; i < tokens.size(); i++) {
        if (tokens[i] == "(") {
            bracketStack.push(i);
        } else if (tokens[i] == ")") {
            if (bracketStack.empty()) {
                qCritical() << "Ошибка: Непарная закрывающая скобка";
                return false;
            }

            int start = bracketStack.top();
            bracketStack.pop();

            // Вычисляем выражение внутри скобок
            QStringList subTokens;
            for (int j = start + 1; j < i; j++) {
                subTokens.append(tokens[j]);
            }

            bool bracketResult = evaluateComplexCondition(subTokens);

            // Заменяем скобки и их содержимое на результат
            tokens[start] = bracketResult ? "1" : "0";
            for (int j = start + 1; j <= i; j++) {
                tokens.removeAt(start + 1);
            }
            i = start;
        }
    }

    if (!bracketStack.empty()) {
        qCritical() << "Ошибка: Непарная открывающая скобка";
        return false;
    }

    // Вычисляем операции &&
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "&&") {
            bool leftVal = (tokens[i-1] == "1" || evaluateSimpleCondition(tokens[i-1]));
            bool rightVal = (tokens[i+1] == "1" || evaluateSimpleCondition(tokens[i+1]));
            bool result = leftVal && rightVal;

            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    // Вычисляем операции ||
    for (int i = 1; i < tokens.size() - 1; ) {
        if (tokens[i] == "||") {
            bool leftVal = (tokens[i-1] == "1" || evaluateSimpleCondition(tokens[i-1]));
            bool rightVal = (tokens[i+1] == "1" || evaluateSimpleCondition(tokens[i+1]));
            bool result = leftVal || rightVal;

            tokens[i-1] = result ? "1" : "0";
            tokens.removeAt(i);
            tokens.removeAt(i);
        } else {
            i++;
        }
    }

    if (tokens.size() != 1) {
        qCritical() << "Ошибка: Неверное сложное условие, оставшиеся токены:" << tokens;
        return false;
    }

    return tokens[0] == "1" || evaluateSimpleCondition(tokens[0]);
}
// счетчик

void Obrabotka::schetchik(const QString& counterExpr, QVariantList loopBody) {
    qDebug() << "Запуск цикла for:" << counterExpr;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    QString varName;
    int startVal, endVal, stepVal;

    if (!parseCounter(counterExpr, varName, startVal, endVal, stepVal)) {
        qWarning() << "Неверный формат счетчика:" << counterExpr;
        return;
    }

    qDebug() << "Цикл for:" << varName << "от" << startVal << "до" << endVal << "шаг" << stepVal;

    if (stepVal == 0) {
        qWarning() << "Шаг цикла не может быть равен 0";
        return;
    }

    // Выполняем цикл
    if (stepVal > 0) {
        for (int i = startVal; i <= endVal; i += stepVal) {
            setValue(varName, i);
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
            } else {
                qDebug() << "Тело цикла пустое!";
            }
        }
    } else {
        for (int i = startVal; i >= endVal; i += stepVal) {
            setValue(varName, i);
            if (!loopBody.isEmpty()) {
                vipolnenie(loopBody);
            } else {
                qDebug() << "Тело цикла пустое!";
            }
        }
    }

    qDebug() << "Цикл for завершен";
}

bool Obrabotka::parseCounter(const QString& expr, QString& varName, int& startVal, int& endVal, int& stepVal) {
    QString expression = expr.simplified();
    expression.replace(" ", "");

    // Форматы:
    // 1. i=1to10
    // 2. i=1to10step2
    // 3. i=1to10шаг2 (русский)

    // Определяем разделители
    int toIndex = expression.indexOf("to");
    if (toIndex == -1) toIndex = expression.indexOf("до");

    if (toIndex == -1) {
        qWarning() << "Не найден разделитель 'to' или 'до' в выражении:" << expression;
        return false;
    }

    // Извлекаем имя переменной и начальное значение
    int equalsIndex = expression.indexOf("=");
    if (equalsIndex == -1 || equalsIndex >= toIndex) {
        qWarning() << "Неверный формат: отсутствует '=' перед 'to/до'";
        return false;
    }

    varName = expression.left(equalsIndex);
    QString startStr = expression.mid(equalsIndex + 1, toIndex - equalsIndex - 1);

    // Определяем конец и шаг
    int stepIndex = expression.indexOf("step", toIndex + 2, Qt::CaseInsensitive);
    if (stepIndex == -1) stepIndex = expression.indexOf("шаг", toIndex + 2, Qt::CaseInsensitive);

    QString endStr, stepStr;
    if (stepIndex != -1) {
        endStr = expression.mid(toIndex + 2, stepIndex - toIndex - 2);
        stepStr = expression.mid(stepIndex + (expression.mid(stepIndex, 1) == "s" ? 4 : 3));
    } else {
        endStr = expression.mid(toIndex + 2);
        stepStr = "1"; // Шаг по умолчанию
    }

    // Парсим значения
    bool ok;
    startVal = parseExpression(startStr);
    endVal = parseExpression(endStr);
    stepVal = parseExpression(stepStr);

    qDebug() << "Парсинг счетчика:" << varName << "=" << startVal << "to" << endVal << "step" << stepVal;

    return true;
}


void Obrabotka::predusl(const QString& condition, QVariantList loopBody) {
    qDebug() << "Запуск цикла while:" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    // Сохраняем оригинальное условие для перепроверки
    QString originalCondition = condition;

    while (parseCondition(originalCondition)) {
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qWarning() << "Превышено максимальное количество итераций цикла while";
            break;
        }

        qDebug() << "Итерация while:" << iteration;
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
        } else {
            qDebug() << "Тело цикла пустое!";
        }

        // После выполнения тела цикла снова проверяем условие
        // Условие будет пересчитано с учетом измененных переменных
    }

    qDebug() << "Цикл while завершен, итераций:" << iteration;
}

void Obrabotka::postusl(const QString& condition, QVariantList loopBody) {
    qDebug() << "Запуск цикла do-while:" << condition;
    qDebug() << "Тело цикла (размер):" << loopBody.size();

    int iteration = 0;
    const int MAX_ITERATIONS = 1000;

    // Сохраняем оригинальное условие для перепроверки
    QString originalCondition = condition;

    do {
        iteration++;
        if (iteration > MAX_ITERATIONS) {
            qWarning() << "Превышено максимальное количество итераций цикла do-while";
            break;
        }

        qDebug() << "Итерация do-while:" << iteration;
        if (!loopBody.isEmpty()) {
            vipolnenie(loopBody);
        } else {
            qDebug() << "Тело цикла пустое!";
        }

        // После выполнения тела цикла снова проверяем условие
        // Условие будет пересчитано с учетом измененных переменных

    } while (parseCondition(originalCondition));

    qDebug() << "Цикл do-while завершен, итераций:" << iteration;
}

void Obrabotka::vipolnenie(QVariantList algorithm) {
    qDebug() << ">>> ВЫПОЛНЕНИЕ АЛГОРИТМА (размер:" << algorithm.size() << ")";

    for (int i = 0; i < algorithm.size(); ++i) {
        QVariant item = algorithm[i];
        qDebug() << "Обрабатываем блок" << i << ":" << item;

        if (!item.canConvert<QVariantList>()) {
            qWarning() << "Блок не является списком";
            continue;
        }

        QVariantList block = item.value<QVariantList>();
        qDebug() << "  Распакованный блок:" << block;

        if (block.size() < 2) {
            qWarning() << "Блок слишком короткий";
            continue;
        }

        QString type = block[0].toString();
        QString content = block[1].toString();

        qDebug() << "  Тип:" << type << "| Содержимое:" << content;

        if (type == "ввод") {
            vvod(content);
        } else if (type == "вывод") {
            vivodim_functionod(content);
        } else if (type == "действие") {
            deistvie(content);
        } else if (type == "усл") {
            QVariantList trueBranch = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            QVariantList falseBranch = block.size() > 3 ? block[3].value<QVariantList>() : QVariantList();
            usl(content, trueBranch, falseBranch);
        } else if (type == "счетчик") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            schetchik(content, loopBody);
        } else if (type == "предусл") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            predusl(content, loopBody);
        } else if (type == "постусл") {
            QVariantList loopBody = block.size() > 2 ? block[2].value<QVariantList>() : QVariantList();
            postusl(content, loopBody);
        } else {
            qWarning() << "Неизвестный тип блока:" << type;
        }
    }

    qDebug() << "<<< ЗАВЕРШЕНИЕ ВЫПОЛНЕНИЯ АЛГОРИТМА";
}


// кнопка запустить
void Obrabotka::myPriem(QVariantList algoritm)
{
    vipolnenie(algoritm);
    peremennie.clear();
}
