migrate((app) => {
  // ------------------------------------------------------------
  // Системный superuser PocketBase для просмотра панели /_/.
  // ------------------------------------------------------------
  try {
    const superusers = app.findCollectionByNameOrId("_superusers")
    const admin = new Record(superusers)
    admin.set("email", "admin@cae.local")
    admin.set("password", "Admin123!")
    app.save(admin)
  } catch (_) {
    // При повторном локальном запуске запись уже может существовать.
  }

  // ------------------------------------------------------------
  // Auth collection: users
  // ------------------------------------------------------------
  const users = new Collection({
    id: "usr000000000001",
    type: "auth",
    name: "users",
    listRule: '@request.auth.role = "manager"',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.body.role = "engineer"',
    updateRule: 'id = @request.auth.id && @request.body.role:changed = false',
    deleteRule: 'id = @request.auth.id',
    authRule: "",
    fields: [
      {
        name: "name",
        type: "text",
        required: true,
        min: 3,
        max: 120,
        presentable: true,
      },
      {
        name: "role",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["engineer", "reviewer", "manager"],
      },
    ],
    passwordAuth: {
      enabled: true,
      identityFields: ["email"],
    },
  })
  app.save(users)

  // ------------------------------------------------------------
  // 1. clients
  // ------------------------------------------------------------
  const clients = new Collection({
    id: "cli000000000001",
    type: "base",
    name: "clients",
    listRule: '@request.auth.role = "manager"',
    viewRule: '@request.auth.role = "manager"',
    createRule: '@request.auth.role = "manager"',
    updateRule: '@request.auth.role = "manager"',
    deleteRule: '@request.auth.role = "manager"',
    fields: [
      { name: "name", type: "text", required: true, min: 2, max: 100, presentable: true },
      { name: "inn", type: "text", required: true, min: 10, max: 12 },
      { name: "email", type: "email", required: true },
      { name: "phone", type: "text", max: 30 },
      { name: "country", type: "select", required: true, maxSelect: 1, values: ["Россия", "Беларусь", "Казахстан"] },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_clients_inn ON clients (inn)",
    ],
  })
  app.save(clients)

  // ------------------------------------------------------------
  // 2. engineers
  // ------------------------------------------------------------
  const engineers = new Collection({
    id: "eng000000000001",
    type: "base",
    name: "engineers",
    listRule: '@request.auth.role = "manager" || @request.auth.role = "engineer"',
    viewRule: '@request.auth.role = "manager" || @request.auth.role = "engineer"',
    createRule: '@request.auth.role = "manager"',
    updateRule: '@request.auth.role = "manager"',
    deleteRule: '@request.auth.role = "manager"',
    fields: [
      { name: "fullName", type: "text", required: true, min: 3, max: 120, presentable: true },
      { name: "specialization", type: "select", required: true, maxSelect: 1, values: ["Конструкции", "Фасады", "Динамика"] },
      { name: "experience", type: "number", required: true, min: 0, max: 50 },
      { name: "email", type: "email", required: true },
    ],
  })
  app.save(engineers)

  // ------------------------------------------------------------
  // 3. projects (clients 1:N projects; engineer 1:N projects)
  // ------------------------------------------------------------
  const projects = new Collection({
    id: "prj000000000001",
    type: "base",
    name: "projects",
    listRule: '@request.auth.role = "manager" || @request.auth.role = "engineer"',
    viewRule: '@request.auth.role = "manager" || @request.auth.role = "engineer"',
    createRule: '@request.auth.role = "manager"',
    updateRule: '@request.auth.role = "manager"',
    deleteRule: '@request.auth.role = "manager"',
    fields: [
      { name: "name", type: "text", required: true, min: 3, max: 120, presentable: true },
      { name: "code", type: "text", required: true, min: 2, max: 30 },
      { name: "client", type: "relation", required: true, maxSelect: 1, collectionId: "cli000000000001", cascadeDelete: false },
      { name: "leadEngineer", type: "relation", required: true, maxSelect: 1, collectionId: "eng000000000001", cascadeDelete: false },
      { name: "status", type: "select", required: true, maxSelect: 1, values: ["Новый", "В работе", "На проверке", "Завершён"] },
      { name: "deadline", type: "date", required: true },
      { name: "description", type: "text", max: 500 },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_projects_code ON projects (code)",
    ],
  })
  app.save(projects)

  // ------------------------------------------------------------
  // 4. materials
  // ------------------------------------------------------------
  const materials = new Collection({
    id: "mat000000000001",
    type: "base",
    name: "materials",
    listRule: '@request.auth.role = "engineer"',
    viewRule: '@request.auth.role = "engineer"',
    createRule: '@request.auth.role = "engineer"',
    updateRule: '@request.auth.role = "engineer"',
    deleteRule: '@request.auth.role = "engineer"',
    fields: [
      { name: "name", type: "text", required: true, max: 80, presentable: true },
      { name: "grade", type: "text", required: true, max: 50 },
      { name: "elasticModulus", type: "number", required: true, min: 1000, max: 500000 },
      { name: "yieldStrength", type: "number", required: true, min: 10, max: 5000 },
      { name: "density", type: "number", required: true, min: 100, max: 30000 },
    ],
  })
  app.save(materials)

  // ------------------------------------------------------------
  // 5. sections (materials 1:N sections)
  // ------------------------------------------------------------
  const sections = new Collection({
    id: "sec000000000001",
    type: "base",
    name: "sections",
    listRule: '@request.auth.role = "engineer"',
    viewRule: '@request.auth.role = "engineer"',
    createRule: '@request.auth.role = "engineer"',
    updateRule: '@request.auth.role = "engineer"',
    deleteRule: '@request.auth.role = "engineer"',
    fields: [
      { name: "name", type: "text", required: true, max: 80, presentable: true },
      { name: "type", type: "select", required: true, maxSelect: 1, values: ["Труба", "Уголок", "Двутавр", "Полоса"] },
      { name: "material", type: "relation", required: true, maxSelect: 1, collectionId: "mat000000000001", cascadeDelete: false },
      { name: "area", type: "number", required: true, min: 1, max: 1000000 },
      { name: "inertia", type: "number", required: true, min: 1, max: 1000000000000 },
    ],
  })
  app.save(sections)

  // ------------------------------------------------------------
  // 6. load_cases
  // ------------------------------------------------------------
  const loadCases = new Collection({
    id: "lod000000000001",
    type: "base",
    name: "load_cases",
    listRule: '@request.auth.role = "engineer"',
    viewRule: '@request.auth.role = "engineer"',
    createRule: '@request.auth.role = "engineer"',
    updateRule: '@request.auth.role = "engineer"',
    deleteRule: '@request.auth.role = "engineer"',
    fields: [
      { name: "name", type: "text", required: true, max: 100, presentable: true },
      { name: "kind", type: "select", required: true, maxSelect: 1, values: ["Ветер", "Снег", "Собственный вес", "Барьерная"] },
      { name: "value", type: "number", required: true, min: 0, max: 1000000 },
      { name: "unit", type: "select", required: true, maxSelect: 1, values: ["кПа", "кН/м", "кН"] },
      { name: "description", type: "text", max: 300 },
    ],
  })
  app.save(loadCases)

  // ------------------------------------------------------------
  // 7. calculations
  // projects 1:N calculations
  // sections 1:N calculations
  // engineers 1:N calculations
  // calculations N:M load_cases
  // ------------------------------------------------------------
  const calculations = new Collection({
    id: "cal000000000001",
    type: "base",
    name: "calculations",
    listRule: '@request.auth.role = "engineer" || @request.auth.role = "reviewer"',
    viewRule: '@request.auth.role = "engineer" || @request.auth.role = "reviewer"',
    createRule: '@request.auth.role = "engineer"',
    updateRule: '@request.auth.role = "engineer"',
    deleteRule: '@request.auth.role = "engineer"',
    fields: [
      { name: "title", type: "text", required: true, min: 3, max: 120, presentable: true },
      { name: "project", type: "relation", required: true, maxSelect: 1, collectionId: "prj000000000001", cascadeDelete: false },
      { name: "engineer", type: "relation", required: true, maxSelect: 1, collectionId: "eng000000000001", cascadeDelete: false },
      { name: "section", type: "relation", required: true, maxSelect: 1, collectionId: "sec000000000001", cascadeDelete: false },
      { name: "loadCases", type: "relation", required: true, minSelect: 1, maxSelect: 20, collectionId: "lod000000000001", cascadeDelete: false },
      { name: "calcType", type: "select", required: true, maxSelect: 1, values: ["Прочность", "Прогиб", "Устойчивость"] },
      { name: "status", type: "select", required: true, maxSelect: 1, values: ["Черновик", "Рассчитан", "На проверке"] },
      { name: "utilization", type: "number", required: true, min: 0, max: 10 },
      { name: "result", type: "text", required: true, max: 500 },
    ],
  })
  app.save(calculations)

  // ------------------------------------------------------------
  // 8. reviews
  // UNIQUE relation calculation => calculations 1:1 reviews
  // ------------------------------------------------------------
  const reviews = new Collection({
    id: "rev000000000001",
    type: "base",
    name: "reviews",
    listRule: '@request.auth.role = "reviewer"',
    viewRule: '@request.auth.role = "reviewer"',
    createRule: '@request.auth.role = "reviewer"',
    updateRule: '@request.auth.role = "reviewer"',
    deleteRule: '@request.auth.role = "reviewer"',
    fields: [
      { name: "calculation", type: "relation", required: true, maxSelect: 1, collectionId: "cal000000000001", cascadeDelete: true },
      { name: "reviewer", type: "text", required: true, min: 3, max: 120, presentable: true },
      { name: "decision", type: "select", required: true, maxSelect: 1, values: ["Согласовано", "На доработку", "Отклонено"] },
      { name: "comment", type: "text", required: true, max: 500 },
      { name: "checkedAt", type: "date", required: true },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_reviews_calculation ON reviews (calculation)",
    ],
  })
  app.save(reviews)

  // ------------------------------------------------------------
  // Демо-пользователи трёх ролей.
  // ------------------------------------------------------------
  function createUser(email, password, name, role) {
    const record = new Record(users)
    record.set("email", email)
    record.set("password", password)
    record.set("name", name)
    record.set("role", role)
    app.save(record)
    return record
  }

  createUser("engineer@cae.local", "Engineer123!", "Иван Инженеров", "engineer")
  createUser("reviewer@cae.local", "Reviewer123!", "Пётр Проверяющий", "reviewer")
  createUser("manager@cae.local", "Manager123!", "Мария Руководитель", "manager")

  function createRecord(collection, data) {
    const record = new Record(collection)
    for (const key in data) {
      record.set(key, data[key])
    }
    app.save(record)
    return record
  }

  // Заказчики
  const client1 = createRecord(clients, { name: "АО Высота", inn: "7701000001", email: "office@visota.local", phone: "+7 495 100-10-10", country: "Россия" })
  const client2 = createRecord(clients, { name: "ООО ФасадПро", inn: "7701000002", email: "info@fasadpro.local", phone: "+7 495 200-20-20", country: "Россия" })
  const client3 = createRecord(clients, { name: "МинскСтрой", inn: "1901000001", email: "office@minskstroy.local", phone: "+375 17 300-30-30", country: "Беларусь" })
  const client4 = createRecord(clients, { name: "KZ Engineering", inn: "120100000001", email: "info@kzeng.local", phone: "+7 7172 40-40-40", country: "Казахстан" })

  // Инженеры
  const eng1 = createRecord(engineers, { fullName: "Алексей Смирнов", specialization: "Конструкции", experience: 8, email: "smirnov@cae.local" })
  const eng2 = createRecord(engineers, { fullName: "Елена Петрова", specialization: "Фасады", experience: 6, email: "petrova@cae.local" })
  const eng3 = createRecord(engineers, { fullName: "Дмитрий Орлов", specialization: "Динамика", experience: 10, email: "orlov@cae.local" })
  const eng4 = createRecord(engineers, { fullName: "Анна Соколова", specialization: "Конструкции", experience: 4, email: "sokolova@cae.local" })

  // Проекты
  const project1 = createRecord(projects, { name: "Бизнес-центр Север", code: "BC-101", client: client1.id, leadEngineer: eng1.id, status: "В работе", deadline: "2026-10-31 00:00:00.000Z", description: "Проверка несущих элементов фасадной подсистемы" })
  const project2 = createRecord(projects, { name: "ЖК Речной", code: "JK-204", client: client2.id, leadEngineer: eng2.id, status: "На проверке", deadline: "2026-11-15 00:00:00.000Z", description: "Расчёт навесного вентилируемого фасада" })
  const project3 = createRecord(projects, { name: "Торговый центр Парк", code: "TC-330", client: client3.id, leadEngineer: eng3.id, status: "Новый", deadline: "2026-12-20 00:00:00.000Z", description: "Динамический расчёт ограждений" })
  const project4 = createRecord(projects, { name: "Офисная башня А", code: "OT-410", client: client4.id, leadEngineer: eng4.id, status: "Завершён", deadline: "2026-09-30 00:00:00.000Z", description: "Проверка стоечно-ригельной системы" })
  const project5 = createRecord(projects, { name: "МФЦ 5.3", code: "MFC-53", client: client1.id, leadEngineer: eng2.id, status: "В работе", deadline: "2026-12-01 00:00:00.000Z", description: "Расчёт фасадного модуля" })
  const project6 = createRecord(projects, { name: "Зенитный фонарь", code: "ZF-620", client: client2.id, leadEngineer: eng1.id, status: "В работе", deadline: "2027-01-20 00:00:00.000Z", description: "Расчёт профилей светопрозрачной конструкции" })
  const project7 = createRecord(projects, { name: "Шумозащитный экран", code: "SE-711", client: client3.id, leadEngineer: eng4.id, status: "Новый", deadline: "2026-11-05 00:00:00.000Z", description: "Проверка ригелей и креплений" })
  const project8 = createRecord(projects, { name: "Атриум Восток", code: "AV-800", client: client4.id, leadEngineer: eng3.id, status: "На проверке", deadline: "2026-10-10 00:00:00.000Z", description: "Расчёт пространственной системы" })
  const project9 = createRecord(projects, { name: "Корпус A1", code: "A1-901", client: client1.id, leadEngineer: eng2.id, status: "В работе", deadline: "2026-12-12 00:00:00.000Z", description: "Расчёт кассет НФС" })

  // Материалы
  const mat1 = createRecord(materials, { name: "Сталь конструкционная", grade: "S235", elasticModulus: 210000, yieldStrength: 235, density: 7850 })
  const mat2 = createRecord(materials, { name: "Сталь конструкционная", grade: "С245", elasticModulus: 206000, yieldStrength: 245, density: 7850 })
  const mat3 = createRecord(materials, { name: "Нержавеющая сталь", grade: "AISI 304", elasticModulus: 193000, yieldStrength: 215, density: 8000 })
  const mat4 = createRecord(materials, { name: "Алюминиевый сплав", grade: "6063-T6", elasticModulus: 70000, yieldStrength: 170, density: 2700 })

  // Сечения
  const sec1 = createRecord(sections, { name: "Труба 120x80x4", type: "Труба", material: mat1.id, area: 1504, inertia: 2900000 })
  const sec2 = createRecord(sections, { name: "Труба 60x40x6", type: "Труба", material: mat2.id, area: 1056, inertia: 510000 })
  const sec3 = createRecord(sections, { name: "Уголок 40x40x1.5", type: "Уголок", material: mat3.id, area: 118, inertia: 18400 })
  const sec4 = createRecord(sections, { name: "Профиль 60x210x3", type: "Труба", material: mat4.id, area: 1584, inertia: 8200000 })
  const sec5 = createRecord(sections, { name: "Полоса 80x8", type: "Полоса", material: mat1.id, area: 640, inertia: 3413 })

  // Нагрузки
  const load1 = createRecord(loadCases, { name: "Ветер зона 1", kind: "Ветер", value: 3.2, unit: "кПа", description: "Положительное давление" })
  const load2 = createRecord(loadCases, { name: "Ветер зона 2", kind: "Ветер", value: 4.8, unit: "кПа", description: "Угловая зона" })
  const load3 = createRecord(loadCases, { name: "Снег основная", kind: "Снег", value: 2.1, unit: "кПа", description: "Расчёт по горизонтальной проекции" })
  const load4 = createRecord(loadCases, { name: "Собственный вес", kind: "Собственный вес", value: 0.8, unit: "кН/м", description: "Вес элементов" })
  const load5 = createRecord(loadCases, { name: "Барьерная", kind: "Барьерная", value: 0.8, unit: "кН", description: "Сосредоточенная нагрузка" })
  const load6 = createRecord(loadCases, { name: "Ветер отсос", kind: "Ветер", value: 2.9, unit: "кПа", description: "Отрицательное давление" })

  // Расчёты (9 записей, чтобы была видна пагинация при perPage=8)
  const calc1 = createRecord(calculations, { title: "Стойка фасада — прочность", project: project1.id, engineer: eng1.id, section: sec1.id, loadCases: [load1.id, load2.id], calcType: "Прочность", status: "Рассчитан", utilization: 0.78, result: "Прочность обеспечена, коэффициент использования 0.78" })
  const calc2 = createRecord(calculations, { title: "Ригель — прогиб", project: project2.id, engineer: eng2.id, section: sec2.id, loadCases: [load1.id, load4.id], calcType: "Прогиб", status: "На проверке", utilization: 0.91, result: "Прогиб 12.4 мм, допустимое значение не превышено" })
  const calc3 = createRecord(calculations, { title: "Профиль фонаря — устойчивость", project: project6.id, engineer: eng1.id, section: sec4.id, loadCases: [load3.id, load4.id], calcType: "Устойчивость", status: "На проверке", utilization: 0.84, result: "Коэффициент устойчивости достаточен" })
  const calc4 = createRecord(calculations, { title: "Кронштейн — прочность", project: project5.id, engineer: eng2.id, section: sec1.id, loadCases: [load1.id, load5.id], calcType: "Прочность", status: "Рассчитан", utilization: 0.67, result: "Несущая способность обеспечена" })
  const calc5 = createRecord(calculations, { title: "Экран — прогиб", project: project7.id, engineer: eng4.id, section: sec5.id, loadCases: [load2.id, load6.id], calcType: "Прогиб", status: "Черновик", utilization: 0.52, result: "Предварительный прогиб 8.1 мм" })
  const calc6 = createRecord(calculations, { title: "Атриум — динамика", project: project8.id, engineer: eng3.id, section: sec4.id, loadCases: [load1.id, load3.id, load4.id], calcType: "Устойчивость", status: "На проверке", utilization: 0.88, result: "Резерв устойчивости 12 процентов" })
  const calc7 = createRecord(calculations, { title: "Кассета A1 — прочность", project: project9.id, engineer: eng2.id, section: sec3.id, loadCases: [load1.id, load6.id], calcType: "Прочность", status: "Рассчитан", utilization: 0.73, result: "Напряжения ниже расчётного сопротивления" })
  const calc8 = createRecord(calculations, { title: "Башня А — прогиб стойки", project: project4.id, engineer: eng4.id, section: sec2.id, loadCases: [load2.id], calcType: "Прогиб", status: "Рассчитан", utilization: 0.61, result: "Критерий L/200 выполнен" })
  const calc9 = createRecord(calculations, { title: "ТЦ Парк — ударная проверка", project: project3.id, engineer: eng3.id, section: sec1.id, loadCases: [load5.id], calcType: "Прочность", status: "Черновик", utilization: 0.95, result: "Требуется уточнение динамической модели" })

  // Проверки. Одному расчёту соответствует не более одной проверки (1:1).
  createRecord(reviews, { calculation: calc1.id, reviewer: "Сергей Кузнецов", decision: "Согласовано", comment: "Замечаний нет", checkedAt: "2026-09-10 00:00:00.000Z" })
  createRecord(reviews, { calculation: calc2.id, reviewer: "Сергей Кузнецов", decision: "На доработку", comment: "Уточнить граничные условия", checkedAt: "2026-09-11 00:00:00.000Z" })
  createRecord(reviews, { calculation: calc3.id, reviewer: "Ольга Волкова", decision: "Согласовано", comment: "Расчёт принят", checkedAt: "2026-09-12 00:00:00.000Z" })
  createRecord(reviews, { calculation: calc4.id, reviewer: "Ольга Волкова", decision: "Согласовано", comment: "Проверка пройдена", checkedAt: "2026-09-13 00:00:00.000Z" })
  createRecord(reviews, { calculation: calc6.id, reviewer: "Сергей Кузнецов", decision: "На доработку", comment: "Добавить пояснение по сочетаниям", checkedAt: "2026-09-14 00:00:00.000Z" })
  createRecord(reviews, { calculation: calc7.id, reviewer: "Ольга Волкова", decision: "Согласовано", comment: "Замечаний нет", checkedAt: "2026-09-15 00:00:00.000Z" })
}, (app) => {
  // Удаление выполняется в обратном порядке связей.
  for (const name of ["reviews", "calculations", "load_cases", "sections", "materials", "projects", "engineers", "clients", "users"]) {
    try {
      const collection = app.findCollectionByNameOrId(name)
      app.delete(collection)
    } catch (_) {}
  }
})
