const STORAGE_KEY = "atodo-brillo-store-v1";
const allowedTargets = [5, 6, 7, 8, 9, 10];

const statusLabels = {
  pending: "Pendiente",
  confirmed: "Confirmado",
  in_progress: "En proceso",
  done: "Terminado",
  cancelled: "Cancelado",
};

const statusClasses = {
  pending: "warn",
  confirmed: "blue",
  in_progress: "blue",
  done: "green",
  cancelled: "red",
};

const categoryLabels = {
  wash: "Lavado",
  interior: "Interior",
  polish: "Pulido",
  ceramic: "Ceramico",
  combo: "Combo",
};

const roleUsers = {
  client: { uid: "local_client", role: "client", displayName: "Cliente" },
  staff: { uid: "local_staff", role: "staff", displayName: "Staff" },
  admin: { uid: "local_admin", role: "admin", displayName: "Admin" },
};

const supabaseClient = createSupabaseClient();

const ui = {
  currentRole: "client",
  authUser: null,
  staffProfile: null,
  authReady: false,
  bookingStep: 1,
  booking: {
    clientName: "",
    clientPhone: "",
    vehicleName: "",
    vehiclePlate: "",
    date: dateInputValue(1),
    time: "10:00",
    serviceId: "",
  },
  editingServiceId: null,
  clientLookupPhone: "",
  toastTimer: null,
  syncTimer: null,
  connectionError: false,
};

let state = loadStore();

renderAll();
initializeAuth();
hydrateSupabaseStore();

document.addEventListener("click", (event) => {
  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;

  const { action, id, serviceId } = actionButton.dataset;

  if (action === "booking-next") nextBookingStep();
  if (action === "booking-prev") previousBookingStep();
  if (action === "select-service") {
    ui.booking.serviceId = serviceId;
    renderBooking();
  }
  if (action === "edit-service") {
    ui.editingServiceId = id;
    renderServicesAdmin();
  }
  if (action === "cancel-service-edit") {
    ui.editingServiceId = null;
    renderServicesAdmin();
  }
  if (action === "toggle-service") toggleService(id);
  if (action === "delete-service") deleteService(id);
  if (action === "open-whatsapp") openWhatsAppForAppointment(id);
  if (action === "redeem-loyalty") redeemLoyalty(id);
  if (action === "delete-expense") deleteExpense(id);
  if (action === "logout") logoutStaff();
});

document.addEventListener("input", (event) => {
  const bookingField = event.target.closest("[data-booking-field]");
  if (bookingField) {
    ui.booking[bookingField.dataset.bookingField] = bookingField.value;
  }
});

document.addEventListener("change", (event) => {
  const statusSelect = event.target.closest("[data-status-appointment]");
  if (statusSelect) {
    updateAppointmentStatus(statusSelect.dataset.statusAppointment, statusSelect.value);
  }
});

document.addEventListener("submit", (event) => {
  event.preventDefault();

  if (event.target.id === "booking-form") {
    createAppointmentFromBooking();
  }

  if (event.target.id === "service-form") {
    saveService(new FormData(event.target));
  }

  if (event.target.id === "expense-form") {
    saveExpense(new FormData(event.target));
  }

  if (event.target.id === "settings-form") {
    saveSettings(new FormData(event.target));
  }

  if (event.target.id === "client-lookup-form") {
    const form = new FormData(event.target);
    ui.clientLookupPhone = String(form.get("phone") || "");
    renderLoyalty();
  }

  if (event.target.id === "staff-login-form") {
    loginStaff(new FormData(event.target));
  }
});

function loadStore() {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) return seedStore();

  try {
    const parsed = JSON.parse(stored);
    if (!parsed.settings || !Array.isArray(parsed.services)) return seedStore();
    return sanitizeStore(parsed);
  } catch {
    return seedStore();
  }
}

function saveStore() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function seedStore() {
  const now = nowIso();
  const settings = {
    businessName: "A Todo Brillo",
    country: "AR",
    province: "Mendoza",
    currency: "ARS",
    locale: "es-AR",
    timezone: "America/Argentina/Mendoza",
    loyaltyTargetServices: 8,
    loyaltyAllowedTargets: allowedTargets,
    whatsappMode: "manual_staff_click",
    updatedBy: "system",
    updatedAt: now,
  };

  const services = [
    {
      id: "srv_lavado_premium",
      name: "Lavado Premium",
      description: "Exterior, llantas, secado tecnico y terminacion con realce.",
      price: 12000,
      estimatedMinutes: 60,
      category: "wash",
      isActive: true,
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "srv_interior_full",
      name: "Interior Full",
      description: "Aspirado profundo, plasticos, tapizados y sanitizacion.",
      price: 22000,
      estimatedMinutes: 120,
      category: "interior",
      isActive: true,
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "srv_combo_brillo",
      name: "Combo Brillo",
      description: "Lavado premium, interior express y proteccion UV.",
      price: 30000,
      estimatedMinutes: 150,
      category: "combo",
      isActive: true,
      sortOrder: 3,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: "srv_pulido_one_step",
      name: "Pulido One Step",
      description: "Correccion ligera de pintura y sellado final.",
      price: 85000,
      estimatedMinutes: 360,
      category: "polish",
      isActive: true,
      sortOrder: 4,
      createdAt: now,
      updatedAt: now,
    },
  ];

  const users = [
    {
      uid: "usr_lucas",
      role: "client",
      displayName: "Lucas Fernandez",
      phone: "261 555 1088",
      normalizedPhone: "5492615551088",
      email: null,
      vehicleName: "Volkswagen Vento",
      vehiclePlate: "AB123CD",
      loyaltyPoints: 4,
      lifetimeServices: 12,
      courtesyWashAvailable: false,
      createdAt: now,
      updatedAt: now,
      lastAppointmentAt: toIsoFromInput(dateInputValue(-9), "18:00"),
    },
    {
      uid: "usr_maria",
      role: "client",
      displayName: "Maria Suarez",
      phone: "261 555 4421",
      normalizedPhone: "5492615554421",
      email: null,
      vehicleName: "Toyota Corolla",
      vehiclePlate: "AC456EF",
      loyaltyPoints: 7,
      lifetimeServices: 7,
      courtesyWashAvailable: false,
      createdAt: now,
      updatedAt: now,
      lastAppointmentAt: toIsoFromInput(dateInputValue(0), "09:00"),
    },
  ];

  const appointments = [
    {
      id: "apt_today_maria",
      clientUid: "usr_maria",
      clientName: "Maria Suarez",
      clientPhone: "261 555 4421",
      normalizedPhone: "5492615554421",
      vehicleName: "Toyota Corolla",
      vehiclePlate: "AC456EF",
      serviceId: "srv_combo_brillo",
      serviceName: "Combo Brillo",
      servicePrice: 30000,
      scheduledAt: toIsoFromInput(dateInputValue(0), "09:00"),
      status: "confirmed",
      paymentStatus: "unpaid",
      paidAmount: 0,
      staffNotes: "Cliente pidio cuidar zocalos interiores.",
      whatsappOpenedAt: null,
      whatsappOpenedBy: null,
      loyaltyPointAwarded: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    },
    {
      id: "apt_tomorrow_lucas",
      clientUid: "usr_lucas",
      clientName: "Lucas Fernandez",
      clientPhone: "261 555 1088",
      normalizedPhone: "5492615551088",
      vehicleName: "Volkswagen Vento",
      vehiclePlate: "AB123CD",
      serviceId: "srv_lavado_premium",
      serviceName: "Lavado Premium",
      servicePrice: 12000,
      scheduledAt: toIsoFromInput(dateInputValue(1), "11:30"),
      status: "pending",
      paymentStatus: "unpaid",
      paidAmount: 0,
      staffNotes: null,
      whatsappOpenedAt: null,
      whatsappOpenedBy: null,
      loyaltyPointAwarded: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    },
  ];

  const expenses = [
    {
      id: "exp_shampoo",
      title: "Shampoo pH neutro",
      amount: 18500,
      category: "supplies",
      expenseDate: toIsoFromInput(dateInputValue(0), "08:00"),
      notes: "Reposicion semanal",
      createdBy: "system",
      createdAt: now,
      updatedAt: now,
    },
  ];

  return {
    settings,
    services,
    users,
    appointments,
    expenses,
    loyaltyEvents: [],
    notifications: [],
  };
}

function sanitizeStore(store) {
  store.settings = {
    ...seedStore().settings,
    ...store.settings,
  };

  if (!isValidLocale(store.settings.locale)) store.settings.locale = "es-AR";
  if (!store.settings.currency || store.settings.currency.length !== 3) store.settings.currency = "ARS";
  if (!store.settings.timezone || typeof store.settings.timezone !== "string") {
    store.settings.timezone = "America/Argentina/Mendoza";
  }
  if (!allowedTargets.includes(Number(store.settings.loyaltyTargetServices))) {
    store.settings.loyaltyTargetServices = 8;
  }

  store.services = Array.isArray(store.services) ? store.services : [];
  store.users = Array.isArray(store.users) ? store.users : [];
  store.appointments = Array.isArray(store.appointments) ? store.appointments : [];
  store.expenses = Array.isArray(store.expenses) ? store.expenses : [];
  store.loyaltyEvents = Array.isArray(store.loyaltyEvents) ? store.loyaltyEvents : [];
  store.notifications = Array.isArray(store.notifications) ? store.notifications : [];

  return store;
}

function isValidLocale(locale) {
  try {
    new Intl.NumberFormat(locale).format(1);
    return true;
  } catch {
    return false;
  }
}

function createSupabaseClient() {
  const config = window.ATB_SUPABASE_CONFIG || {};
  const hasConfig = Boolean(config.url && config.anonKey);

  if (!hasConfig || !window.supabase?.createClient) {
    return null;
  }

  return window.supabase.createClient(config.url, config.anonKey);
}

async function hydrateSupabaseStore() {
  if (!supabaseClient) return;

  try {
    showToast("Conectando con Supabase...");
    const remoteState = await fetchSupabaseState(isStaffOrAdmin());
    const hasRemoteData = remoteState.services.length || remoteState.users.length || remoteState.appointments.length || remoteState.expenses.length;
    ui.connectionError = false;

    if (!hasRemoteData) {
      if (isAdmin()) await syncFullStateToSupabase();
      showToast("Supabase conectado.");
      return;
    }

    state = remoteState;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    showToast("Datos cargados desde Supabase.");
    renderAll();
  } catch (error) {
    ui.connectionError = true;
    state = {
      ...state,
      services: [],
      users: [],
      appointments: [],
      expenses: [],
      loyaltyEvents: [],
      notifications: [],
    };
    showToast(`No se pudo conectar con la base de datos. ${error.message || ""}`);
    renderAll();
  }
}

async function fetchSupabaseState(includeInternal = false) {
  const settingsResult = await supabaseClient.from("settings").select("*").eq("id", "business").maybeSingle();
  const servicesResult = await supabaseClient.from("services").select("*").order("sort_order", { ascending: true });

  let usersResult = { data: [], error: null };
  let appointmentsResult = { data: [], error: null };
  let expensesResult = { data: [], error: null };
  let loyaltyEventsResult = { data: [], error: null };
  let notificationsResult = { data: [], error: null };

  if (includeInternal) {
    [
      usersResult,
      appointmentsResult,
      expensesResult,
      loyaltyEventsResult,
      notificationsResult,
    ] = await Promise.all([
      supabaseClient.from("users").select("*"),
      supabaseClient.from("appointments").select("*").order("scheduled_at", { ascending: true }),
      supabaseClient.from("expenses").select("*").order("expense_date", { ascending: false }),
      supabaseClient.from("loyalty_events").select("*").order("created_at", { ascending: false }),
      supabaseClient.from("notifications").select("*").order("created_at", { ascending: false }),
    ]);
  }

  const results = [settingsResult, servicesResult, usersResult, appointmentsResult, expensesResult, loyaltyEventsResult, notificationsResult];
  const firstError = results.find((result) => result.error)?.error;
  if (firstError) throw firstError;

  return {
    settings: sanitizeSettings(settingsFromRow(settingsResult.data) || state.settings),
    services: (servicesResult.data || []).map(serviceFromRow),
    users: includeInternal ? (usersResult.data || []).map(userFromRow) : [],
    appointments: includeInternal ? (appointmentsResult.data || []).map(appointmentFromRow) : [],
    expenses: includeInternal ? (expensesResult.data || []).map(expenseFromRow) : [],
    loyaltyEvents: includeInternal ? (loyaltyEventsResult.data || []).map(loyaltyEventFromRow) : [],
    notifications: includeInternal ? (notificationsResult.data || []).map(notificationFromRow) : [],
  };
}

async function syncFullStateToSupabase() {
  if (!supabaseClient) return;

  await assertSupabaseResult(supabaseClient.from("settings").upsert(settingsToRow(state.settings), { onConflict: "id" }));
  if (state.services.length) await assertSupabaseResult(supabaseClient.from("services").upsert(state.services.map(serviceToRow), { onConflict: "id" }));
  if (state.users.length) await assertSupabaseResult(supabaseClient.from("users").upsert(state.users.map(userToRow), { onConflict: "uid" }));
  if (state.appointments.length) await assertSupabaseResult(supabaseClient.from("appointments").upsert(state.appointments.map(appointmentToRow), { onConflict: "id" }));
  if (state.expenses.length) await assertSupabaseResult(supabaseClient.from("expenses").upsert(state.expenses.map(expenseToRow), { onConflict: "id" }));
  if (state.loyaltyEvents.length) await assertSupabaseResult(supabaseClient.from("loyalty_events").upsert(state.loyaltyEvents.map(loyaltyEventToRow), { onConflict: "id" }));
  if (state.notifications.length) await assertSupabaseResult(supabaseClient.from("notifications").upsert(state.notifications.map(notificationToRow), { onConflict: "id" }));
}

async function deleteSupabaseRow(table, idColumn, id) {
  if (!supabaseClient) return;

  const { error } = await supabaseClient.from(table).delete().eq(idColumn, id);
  if (error) showToast(`No se pudo borrar en Supabase: ${error.message}`);
}

async function assertSupabaseResult(request) {
  const { error } = await request;
  if (error) throw error;
}

async function initializeAuth() {
  if (!supabaseClient) {
    ui.authReady = true;
    renderAll();
    return;
  }

  const { data } = await supabaseClient.auth.getSession();
  await applySession(data.session);

  supabaseClient.auth.onAuthStateChange(async (_event, session) => {
    await applySession(session);
  });
}

async function applySession(session) {
  ui.authUser = session?.user || null;
  ui.staffProfile = null;
  ui.currentRole = "client";

  if (ui.authUser) {
    ui.staffProfile = await fetchStaffProfile(ui.authUser.id);

    if (!ui.staffProfile?.isActive) {
      showToast("Tu usuario no tiene permiso interno activo.");
      await supabaseClient.auth.signOut();
      ui.authUser = null;
      ui.staffProfile = null;
    } else {
      ui.currentRole = ui.staffProfile.role;
      await hydrateSupabaseStore();
    }
  }

  ui.authReady = true;
  renderAll();
}

async function fetchStaffProfile(userId) {
  const { data, error } = await supabaseClient
    .from("staff_profiles")
    .select("*")
    .eq("user_id", userId)
    .eq("is_active", true)
    .maybeSingle();

  if (error) {
    showToast(`No se pudo leer el perfil interno: ${error.message}`);
    return null;
  }

  if (!data) return null;

  return {
    userId: data.user_id,
    email: data.email,
    displayName: data.display_name,
    role: data.role,
    isActive: data.is_active,
  };
}

async function loginStaff(form) {
  if (!supabaseClient) {
    showToast("Primero conecta Supabase para usar login.");
    return;
  }

  const email = String(form.get("email") || "").trim();
  const password = String(form.get("password") || "");

  if (!email || !password) {
    showToast("Ingresa email y contrasena.");
    return;
  }

  const { error } = await supabaseClient.auth.signInWithPassword({ email, password });
  if (error) {
    showToast(`No se pudo ingresar: ${error.message}`);
    return;
  }

  showToast("Ingreso correcto.");
}

async function logoutStaff() {
  if (!supabaseClient) return;
  await supabaseClient.auth.signOut();
  ui.authUser = null;
  ui.staffProfile = null;
  ui.currentRole = "client";
  await hydrateSupabaseStore();
  showToast("Sesion cerrada.");
  renderAll();
}

function persistPublicBooking(user, appointment) {
  if (!supabaseClient) return;

  (async () => {
    const userResult = await supabaseClient.from("users").insert(userToRow(user));
    if (userResult.error && userResult.error.code !== "23505") throw userResult.error;

    await assertSupabaseResult(supabaseClient.from("appointments").insert(appointmentToRow(appointment)));
  })().catch((error) => showToast(`No se pudo guardar en Supabase: ${error.message || ""}`));
}

function syncOperationalStateToSupabase() {
  if (!supabaseClient || !isStaffOrAdmin()) return;

  Promise.all([
    state.users.length ? assertSupabaseResult(supabaseClient.from("users").upsert(state.users.map(userToRow), { onConflict: "uid" })) : null,
    state.appointments.length ? assertSupabaseResult(supabaseClient.from("appointments").upsert(state.appointments.map(appointmentToRow), { onConflict: "id" })) : null,
    state.loyaltyEvents.length ? assertSupabaseResult(supabaseClient.from("loyalty_events").upsert(state.loyaltyEvents.map(loyaltyEventToRow), { onConflict: "id" })) : null,
    state.notifications.length ? assertSupabaseResult(supabaseClient.from("notifications").upsert(state.notifications.map(notificationToRow), { onConflict: "id" })) : null,
  ]).catch((error) => showToast(`No se pudo sincronizar operacion: ${error.message || ""}`));
}

function syncAdminStateToSupabase() {
  if (!supabaseClient || !isAdmin()) return;
  syncFullStateToSupabase().catch((error) => showToast(`No se pudo sincronizar admin: ${error.message || ""}`));
}

function settingsFromRow(row) {
  if (!row) return null;
  return {
    businessName: row.business_name,
    country: row.country,
    province: row.province,
    currency: row.currency,
    locale: row.locale,
    timezone: row.timezone,
    loyaltyTargetServices: row.loyalty_target_services,
    loyaltyAllowedTargets: row.loyalty_allowed_targets || allowedTargets,
    whatsappMode: row.whatsapp_mode,
    updatedBy: row.updated_by,
    updatedAt: row.updated_at,
  };
}

function sanitizeSettings(settings) {
  const clean = {
    ...seedStore().settings,
    ...settings,
  };

  if (!isValidLocale(clean.locale)) clean.locale = "es-AR";
  if (!clean.currency || clean.currency.length !== 3) clean.currency = "ARS";
  if (!allowedTargets.includes(Number(clean.loyaltyTargetServices))) clean.loyaltyTargetServices = 8;

  return clean;
}

function settingsToRow(settings) {
  return {
    id: "business",
    business_name: settings.businessName,
    country: settings.country,
    province: settings.province,
    currency: settings.currency,
    locale: settings.locale,
    timezone: settings.timezone,
    loyalty_target_services: settings.loyaltyTargetServices,
    loyalty_allowed_targets: settings.loyaltyAllowedTargets || allowedTargets,
    whatsapp_mode: settings.whatsappMode,
    updated_by: settings.updatedBy,
    updated_at: settings.updatedAt,
  };
}

function serviceFromRow(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    price: Number(row.price),
    estimatedMinutes: row.estimated_minutes,
    category: row.category,
    isActive: row.is_active,
    sortOrder: row.sort_order,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function serviceToRow(service) {
  return {
    id: service.id,
    name: service.name,
    description: service.description,
    price: service.price,
    estimated_minutes: service.estimatedMinutes,
    category: service.category,
    is_active: service.isActive,
    sort_order: service.sortOrder,
    created_at: service.createdAt,
    updated_at: service.updatedAt,
  };
}

function userFromRow(row) {
  return {
    uid: row.uid,
    role: row.role,
    displayName: row.display_name,
    phone: row.phone,
    normalizedPhone: row.normalized_phone,
    email: row.email,
    vehicleName: row.vehicle_name,
    vehiclePlate: row.vehicle_plate,
    loyaltyPoints: row.loyalty_points,
    lifetimeServices: row.lifetime_services,
    courtesyWashAvailable: row.courtesy_wash_available,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastAppointmentAt: row.last_appointment_at,
  };
}

function userToRow(user) {
  return {
    uid: user.uid,
    role: user.role,
    display_name: user.displayName,
    phone: user.phone,
    normalized_phone: user.normalizedPhone,
    email: user.email,
    vehicle_name: user.vehicleName,
    vehicle_plate: user.vehiclePlate,
    loyalty_points: user.loyaltyPoints,
    lifetime_services: user.lifetimeServices,
    courtesy_wash_available: user.courtesyWashAvailable,
    created_at: user.createdAt,
    updated_at: user.updatedAt,
    last_appointment_at: user.lastAppointmentAt,
  };
}

function appointmentFromRow(row) {
  return {
    id: row.id,
    clientUid: row.client_uid,
    clientName: row.client_name,
    clientPhone: row.client_phone,
    normalizedPhone: row.normalized_phone,
    vehicleName: row.vehicle_name,
    vehiclePlate: row.vehicle_plate,
    serviceId: row.service_id,
    serviceName: row.service_name,
    servicePrice: Number(row.service_price),
    scheduledAt: row.scheduled_at,
    status: row.status,
    paymentStatus: row.payment_status,
    paidAmount: Number(row.paid_amount),
    staffNotes: row.staff_notes,
    whatsappOpenedAt: row.whatsapp_opened_at,
    whatsappOpenedBy: row.whatsapp_opened_by,
    loyaltyPointAwarded: row.loyalty_point_awarded,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    completedAt: row.completed_at,
  };
}

function appointmentToRow(appointment) {
  return {
    id: appointment.id,
    client_uid: appointment.clientUid,
    client_name: appointment.clientName,
    client_phone: appointment.clientPhone,
    normalized_phone: appointment.normalizedPhone,
    vehicle_name: appointment.vehicleName,
    vehicle_plate: appointment.vehiclePlate,
    service_id: appointment.serviceId,
    service_name: appointment.serviceName,
    service_price: appointment.servicePrice,
    scheduled_at: appointment.scheduledAt,
    status: appointment.status,
    payment_status: appointment.paymentStatus,
    paid_amount: appointment.paidAmount,
    staff_notes: appointment.staffNotes,
    whatsapp_opened_at: appointment.whatsappOpenedAt,
    whatsapp_opened_by: appointment.whatsappOpenedBy,
    loyalty_point_awarded: appointment.loyaltyPointAwarded,
    created_at: appointment.createdAt,
    updated_at: appointment.updatedAt,
    completed_at: appointment.completedAt,
  };
}

function expenseFromRow(row) {
  return {
    id: row.id,
    title: row.title,
    amount: Number(row.amount),
    category: row.category,
    expenseDate: row.expense_date,
    notes: row.notes,
    createdBy: row.created_by,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function expenseToRow(expense) {
  return {
    id: expense.id,
    title: expense.title,
    amount: expense.amount,
    category: expense.category,
    expense_date: expense.expenseDate,
    notes: expense.notes,
    created_by: expense.createdBy,
    created_at: expense.createdAt,
    updated_at: expense.updatedAt,
  };
}

function loyaltyEventFromRow(row) {
  return {
    id: row.id,
    userUid: row.user_uid,
    appointmentId: row.appointment_id,
    type: row.type,
    points: row.points,
    reason: row.reason,
    createdBy: row.created_by,
    createdAt: row.created_at,
  };
}

function loyaltyEventToRow(event) {
  return {
    id: event.id,
    user_uid: event.userUid,
    appointment_id: event.appointmentId,
    type: event.type,
    points: event.points,
    reason: event.reason,
    created_by: event.createdBy,
    created_at: event.createdAt,
  };
}

function notificationFromRow(row) {
  return {
    id: row.id,
    appointmentId: row.appointment_id,
    userUid: row.user_uid,
    channel: row.channel,
    type: row.type,
    status: row.status,
    messagePreview: row.message_preview,
    createdAt: row.created_at,
    openedAt: row.opened_at,
  };
}

function notificationToRow(notification) {
  return {
    id: notification.id,
    appointment_id: notification.appointmentId,
    user_uid: notification.userUid,
    channel: notification.channel,
    type: notification.type,
    status: notification.status,
    message_preview: notification.messagePreview,
    created_at: notification.createdAt,
    opened_at: notification.openedAt,
  };
}

function renderAll() {
  renderAuthStatus();
  renderStaffLogin();
  renderHeroMetrics();
  renderBooking();
  renderOperations();
  renderServicesAdmin();
  renderFinance();
  renderSettings();
  renderLoyalty();
  applyRoleVisibility();
  refreshIcons();
}

function renderAuthStatus() {
  const container = document.getElementById("auth-status");
  if (!container) return;

  if (isStaffOrAdmin()) {
    const profile = ui.staffProfile || currentUser();
    container.innerHTML = `
      <span class="auth-chip ${ui.currentRole}">
        ${escapeHtml(profile.displayName || profile.email || "Usuario")}
        <small>${ui.currentRole}</small>
        <button type="button" data-action="logout">Salir</button>
      </span>
    `;
    return;
  }

  container.innerHTML = `
    <a class="auth-chip" href="#ingreso">
      <i data-lucide="lock-keyhole"></i>
      Ingreso staff
    </a>
  `;
}

function renderStaffLogin() {
  const form = document.getElementById("staff-login-form");
  if (!form) return;

  if (isStaffOrAdmin()) {
    form.innerHTML = `
      <div>
        <p class="eyebrow">Sesion activa</p>
        <h3 class="mt-2 text-2xl font-black">${ui.currentRole === "admin" ? "Administrador" : "Staff"} conectado</h3>
        <p class="field-help">Ya podes usar el panel interno segun tu rol.</p>
      </div>
      <div class="booking-actions">
        <a class="primary-action" href="#panel">Ir al panel</a>
        <button class="plain-button" type="button" data-action="logout">Cerrar sesion</button>
      </div>
    `;
    return;
  }

  form.innerHTML = `
    <div>
      <p class="eyebrow">Supabase Auth</p>
      <h3 class="mt-2 text-2xl font-black">Entrar al panel</h3>
      <p class="field-help">Solo usuarios creados como staff o admin en Supabase pueden acceder.</p>
    </div>
    <div class="form-grid">
      ${simpleInput("Email", "email", "", "email", "admin@atodobrillo.com")}
      ${simpleInput("Contrasena", "password", "", "password", "Tu contrasena")}
    </div>
    <div class="booking-actions">
      <button class="primary-action" type="submit">Ingresar</button>
    </div>
  `;
}

function renderHeroMetrics() {
  const doneCount = state.appointments.filter((item) => item.status === "done").length;
  const metric = document.getElementById("metric-washes");
  if (metric) metric.textContent = `${formatNumber(1240 + doneCount)}+`;
}

function renderBooking() {
  const progress = document.getElementById("booking-progress");
  const form = document.getElementById("booking-form");
  if (!progress || !form) return;

  if (ui.connectionError) {
    progress.innerHTML = "";
    form.innerHTML = `
      <div class="empty-state">
        No se pudo conectar con la base de datos. Recarga la pagina en unos minutos o contacta a A Todo Brillo por WhatsApp.
      </div>
    `;
    return;
  }

  const labels = ["Nombre", "WhatsApp", "Vehiculo", "Fecha", "Servicio"];
  progress.innerHTML = labels
    .map((label, index) => {
      const step = index + 1;
      const stateClass = step === ui.bookingStep ? "active" : step < ui.bookingStep ? "done" : "";
      return `<button type="button" class="${stateClass}" data-action="jump-booking" disabled>${step}. ${label}</button>`;
    })
    .join("");

  form.innerHTML = `${renderBookingStep()}${renderBookingActions()}`;
}

function renderBookingStep() {
  const booking = ui.booking;

  if (ui.bookingStep === 1) {
    return `
      <div class="form-grid">
        <div>
          <p class="eyebrow">Paso 1</p>
          <h3 class="mt-2 text-2xl font-black">Tus datos</h3>
          <p class="field-help">Usamos el nombre para identificar tu turno y preparar el mensaje de finalizacion.</p>
        </div>
        ${field("Nombre completo", "clientName", booking.clientName, "text", "Ej: Juan Perez")}
      </div>
    `;
  }

  if (ui.bookingStep === 2) {
    return `
      <div class="form-grid">
        <div>
          <p class="eyebrow">Paso 2</p>
          <h3 class="mt-2 text-2xl font-black">WhatsApp</h3>
          <p class="field-help">Se normaliza para usar wa.me cuando el staff avise que el vehiculo esta listo.</p>
        </div>
        ${field("WhatsApp", "clientPhone", booking.clientPhone, "tel", "Ej: 261 555 1234")}
      </div>
    `;
  }

  if (ui.bookingStep === 3) {
    return `
      <div class="form-grid two">
        <div class="md:col-span-2">
          <p class="eyebrow">Paso 3</p>
          <h3 class="mt-2 text-2xl font-black">Vehiculo</h3>
          <p class="field-help">El nombre del vehiculo aparece en agenda, Club de Brillo y mensaje de WhatsApp.</p>
        </div>
        ${field("Vehiculo", "vehicleName", booking.vehicleName, "text", "Ej: Toyota Hilux")}
        ${field("Patente", "vehiclePlate", booking.vehiclePlate, "text", "Opcional")}
      </div>
    `;
  }

  if (ui.bookingStep === 4) {
    return `
      <div class="form-grid two">
        <div class="md:col-span-2">
          <p class="eyebrow">Paso 4</p>
          <h3 class="mt-2 text-2xl font-black">Fecha y hora</h3>
          <p class="field-help">La agenda usa zona horaria Mendoza para resaltar trabajos del dia.</p>
        </div>
        ${field("Fecha", "date", booking.date, "date", "", `min="${dateInputValue(0)}"`)}
        ${field("Hora", "time", booking.time, "time", "", "")}
      </div>
    `;
  }

  const activeServices = getActiveServices();

  if (!activeServices.length) {
    return `
      <div class="form-grid">
        <div>
          <p class="eyebrow">Servicios</p>
          <h3 class="mt-2 text-2xl font-black">No hay servicios disponibles</h3>
          <p class="field-help">El catalogo no tiene servicios activos. Contacta a A Todo Brillo para reservar.</p>
        </div>
      </div>
    `;
  }

  return `
    <div class="form-grid">
      <div>
        <p class="eyebrow">Paso 5</p>
        <h3 class="mt-2 text-2xl font-black">Elegir servicio</h3>
        <p class="field-help">El precio queda copiado en el turno para preservar historicos.</p>
      </div>
      <div class="service-options">
        ${activeServices
          .map((service) => {
            const selected = booking.serviceId === service.id ? "selected" : "";
            return `
              <button class="service-option ${selected}" type="button" data-action="select-service" data-service-id="${service.id}">
                <strong>${escapeHtml(service.name)}</strong>
                <p class="muted">${escapeHtml(service.description)}</p>
                <span>${formatMoney(service.price)}</span>
                <small class="muted">${service.estimatedMinutes} min - ${categoryLabels[service.category]}</small>
              </button>
            `;
          })
          .join("")}
      </div>
    </div>
  `;
}

function renderBookingActions() {
  const prev = ui.bookingStep > 1
    ? `<button class="plain-button" type="button" data-action="booking-prev">Volver</button>`
    : "";
  const next = ui.bookingStep < 5
    ? `<button class="primary-action" type="button" data-action="booking-next">Continuar</button>`
    : `<button class="primary-action" type="submit">Confirmar reserva</button>`;

  return `<div class="booking-actions">${prev}${next}</div>`;
}

function field(label, name, value, type, placeholder = "", extra = "") {
  return `
    <div class="field">
      <label for="${name}">${label}</label>
      <input id="${name}" name="${name}" type="${type}" value="${escapeAttr(value || "")}" placeholder="${escapeAttr(placeholder)}" data-booking-field="${name}" ${extra} />
    </div>
  `;
}

function nextBookingStep() {
  if (!validateBookingStep(ui.bookingStep)) return;
  ui.bookingStep = Math.min(5, ui.bookingStep + 1);
  renderBooking();
}

function previousBookingStep() {
  ui.bookingStep = Math.max(1, ui.bookingStep - 1);
  renderBooking();
}

function validateBookingStep(step) {
  const booking = ui.booking;

  if (step === 1 && booking.clientName.trim().length < 2) {
    showToast("Ingresa el nombre del cliente.");
    return false;
  }

  if (step === 2 && normalizePhone(booking.clientPhone).length < 12) {
    showToast("Ingresa un WhatsApp valido de Argentina.");
    return false;
  }

  if (step === 3 && booking.vehicleName.trim().length < 2) {
    showToast("Ingresa el vehiculo.");
    return false;
  }

  if (step === 4 && (!booking.date || !booking.time)) {
    showToast("Elegi fecha y hora.");
    return false;
  }

  if (step === 5 && !state.services.some((service) => service.id === booking.serviceId && service.isActive)) {
    showToast("Elegi un servicio activo.");
    return false;
  }

  return true;
}

function createAppointmentFromBooking() {
  if (ui.connectionError || (supabaseClient && !state.services.length)) {
    showToast("No se pudo conectar con la base de datos. Intenta de nuevo en unos minutos.");
    return;
  }

  for (let step = 1; step <= 5; step += 1) {
    if (!validateBookingStep(step)) {
      ui.bookingStep = step;
      renderBooking();
      return;
    }
  }

  const service = state.services.find((item) => item.id === ui.booking.serviceId);
  const normalizedPhone = normalizePhone(ui.booking.clientPhone);
  const user = upsertClientFromBooking(normalizedPhone);
  const now = nowIso();

  const appointment = {
    id: makeId("apt"),
    clientUid: user.uid,
    clientName: ui.booking.clientName.trim(),
    clientPhone: ui.booking.clientPhone.trim(),
    normalizedPhone,
    vehicleName: ui.booking.vehicleName.trim(),
    vehiclePlate: ui.booking.vehiclePlate.trim() || null,
    serviceId: service.id,
    serviceName: service.name,
    servicePrice: Number(service.price),
    scheduledAt: toIsoFromInput(ui.booking.date, ui.booking.time),
    status: "pending",
    paymentStatus: "unpaid",
    paidAmount: 0,
    staffNotes: null,
    whatsappOpenedAt: null,
    whatsappOpenedBy: null,
    loyaltyPointAwarded: false,
    createdAt: now,
    updatedAt: now,
    completedAt: null,
  };

  state.appointments.push(appointment);

  ui.clientLookupPhone = ui.booking.clientPhone;
  ui.booking = {
    clientName: "",
    clientPhone: "",
    vehicleName: "",
    vehiclePlate: "",
    date: dateInputValue(1),
    time: "10:00",
    serviceId: "",
  };
  ui.bookingStep = 1;

  saveStore();
  persistPublicBooking(user, appointment);
  showToast("Reserva creada. Ya aparece en la agenda del staff.");
  renderAll();
}

function upsertClientFromBooking(normalizedPhone) {
  const now = nowIso();
  let user = state.users.find((item) => item.normalizedPhone === normalizedPhone && item.role === "client");

  if (!user) {
    user = {
      uid: makeId("usr"),
      role: "client",
      displayName: ui.booking.clientName.trim(),
      phone: ui.booking.clientPhone.trim(),
      normalizedPhone,
      email: null,
      vehicleName: ui.booking.vehicleName.trim(),
      vehiclePlate: ui.booking.vehiclePlate.trim() || null,
      loyaltyPoints: 0,
      lifetimeServices: 0,
      courtesyWashAvailable: false,
      createdAt: now,
      updatedAt: now,
      lastAppointmentAt: toIsoFromInput(ui.booking.date, ui.booking.time),
    };
    state.users.push(user);
  } else {
    user.displayName = ui.booking.clientName.trim();
    user.phone = ui.booking.clientPhone.trim();
    user.vehicleName = ui.booking.vehicleName.trim();
    user.vehiclePlate = ui.booking.vehiclePlate.trim() || null;
    user.updatedAt = now;
    user.lastAppointmentAt = toIsoFromInput(ui.booking.date, ui.booking.time);
  }

  return user;
}

function renderOperations() {
  renderOperationsKpis();
  renderAgenda();
}

function renderOperationsKpis() {
  const target = state.settings.loyaltyTargetServices;
  const active = state.appointments.filter((item) => !["done", "cancelled"].includes(item.status)).length;
  const today = state.appointments.filter((item) => isToday(item.scheduledAt) && item.status !== "cancelled").length;
  const completed = state.appointments.filter((item) => item.status === "done").length;
  const rewards = state.users.filter((item) => item.role === "client" && item.loyaltyPoints >= target).length;

  setHtml("operations-kpis", `
    ${kpi("Activos", active)}
    ${kpi("Hoy", today)}
    ${kpi("Terminados", completed)}
    ${kpi("Premios listos", rewards)}
  `);
}

function renderAgenda() {
  const list = document.getElementById("agenda-list");
  if (!list) return;

  const appointments = [...state.appointments]
    .filter((item) => item.status !== "cancelled")
    .sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt));

  if (!appointments.length) {
    list.innerHTML = `<div class="empty-state">Todavia no hay trabajos cargados.</div>`;
    return;
  }

  list.innerHTML = appointments.map(renderAppointmentCard).join("");
}

function renderAppointmentCard(appointment) {
  const today = isToday(appointment.scheduledAt);
  const done = appointment.status === "done";
  const canUseWhatsApp = isStaffOrAdmin() && done;
  const statusClass = statusClasses[appointment.status] || "blue";

  return `
    <article class="agenda-card ${today ? "today" : ""} ${done ? "done" : ""}">
      <div class="card-head">
        <div>
          <h4>${escapeHtml(appointment.vehicleName)}</h4>
          <div class="card-meta">
            <span>${escapeHtml(appointment.clientName)}</span>
            <span>${formatDateTime(appointment.scheduledAt)}</span>
            <span>${escapeHtml(appointment.serviceName)}</span>
            <span>${formatMoney(appointment.servicePrice)}</span>
          </div>
        </div>
        <span class="badge ${statusClass}">${today ? "Hoy - " : ""}${statusLabels[appointment.status]}</span>
      </div>
      ${appointment.staffNotes ? `<p class="muted mt-3">${escapeHtml(appointment.staffNotes)}</p>` : ""}
      <div class="row-actions">
        ${renderStatusControl(appointment)}
        ${canUseWhatsApp ? renderWhatsappButton(appointment) : ""}
      </div>
    </article>
  `;
}

function renderStatusControl(appointment) {
  if (!isStaffOrAdmin()) {
    return `<span class="badge blue">Solo lectura</span>`;
  }

  if (appointment.status === "done") {
    return `<span class="badge green">Finalizado ${appointment.whatsappOpenedAt ? "- WhatsApp abierto" : ""}</span>`;
  }

  return `
    <select class="status-select" data-status-appointment="${appointment.id}">
      ${["pending", "confirmed", "in_progress", "done", "cancelled"]
        .map((status) => `<option value="${status}" ${appointment.status === status ? "selected" : ""}>${statusLabels[status]}</option>`)
        .join("")}
    </select>
  `;
}

function renderWhatsappButton(appointment) {
  const opened = appointment.whatsappOpenedAt ? "Reabrir WhatsApp" : "Avisar por WhatsApp";
  return `
    <button class="success-button" type="button" data-action="open-whatsapp" data-id="${appointment.id}">
      <i data-lucide="message-circle"></i>
      ${opened}
    </button>
  `;
}

function updateAppointmentStatus(id, nextStatus) {
  const appointment = state.appointments.find((item) => item.id === id);
  if (!appointment) return;

  appointment.status = nextStatus;
  appointment.updatedAt = nowIso();

  if (nextStatus === "done") {
    completeAppointment(appointment);
  }

  saveStore();
  syncOperationalStateToSupabase();
  showToast(nextStatus === "done" ? "Trabajo terminado. WhatsApp quedo disponible para clic manual." : "Estado actualizado.");
  renderAll();
}

function completeAppointment(appointment) {
  const now = nowIso();
  appointment.completedAt = appointment.completedAt || now;
  appointment.paymentStatus = "paid";
  appointment.paidAmount = appointment.servicePrice;

  if (!appointment.loyaltyPointAwarded) {
    const user = state.users.find((item) => item.uid === appointment.clientUid);
    if (user) {
      user.loyaltyPoints += 1;
      user.lifetimeServices += 1;
      user.lastAppointmentAt = now;
      user.updatedAt = now;
      user.courtesyWashAvailable = user.loyaltyPoints >= state.settings.loyaltyTargetServices;

      state.loyaltyEvents.push({
        id: makeId("loy"),
        userUid: user.uid,
        appointmentId: appointment.id,
        type: "earned",
        points: 1,
        reason: "Servicio completado",
        createdBy: "system",
        createdAt: now,
      });
    }
    appointment.loyaltyPointAwarded = true;
  }
}

function openWhatsAppForAppointment(id) {
  const appointment = state.appointments.find((item) => item.id === id);
  if (!appointment) return;

  if (!isStaffOrAdmin()) {
    showToast("Solo staff o admin puede abrir WhatsApp desde el panel.");
    return;
  }

  if (appointment.status !== "done") {
    showToast("WhatsApp se habilita cuando el trabajo esta terminado.");
    return;
  }

  if (appointment.normalizedPhone.length < 12) {
    showToast("El telefono no parece valido. Revisalo antes de avisar.");
    return;
  }

  const message = `Hola ${appointment.clientName}, tu ${appointment.vehicleName} ya esta listo. Gracias por confiar en A Todo Brillo. Te esperamos para retirarlo cuando gustes.`;
  const url = `https://wa.me/${appointment.normalizedPhone}?text=${encodeURIComponent(message)}`;
  window.open(url, "_blank", "noopener,noreferrer");

  const now = nowIso();
  appointment.whatsappOpenedAt = now;
  appointment.whatsappOpenedBy = currentUser().uid;
  appointment.updatedAt = now;
  state.notifications.push({
    id: makeId("ntf"),
    appointmentId: appointment.id,
    userUid: appointment.clientUid,
    channel: "whatsapp",
    type: "job_done",
    status: "opened",
    messagePreview: message,
    createdAt: now,
    openedAt: now,
  });

  saveStore();
  syncOperationalStateToSupabase();
  showToast("WhatsApp abierto y registrado en el turno.");
  renderAll();
}

function renderServicesAdmin() {
  renderServiceForm();
  renderServicesAdminList();
}

function renderServiceForm() {
  const form = document.getElementById("service-form");
  if (!form) return;

  const editing = state.services.find((item) => item.id === ui.editingServiceId);
  const service = editing || {
    name: "",
    description: "",
    price: "",
    estimatedMinutes: 60,
    category: "wash",
    sortOrder: state.services.length + 1,
    isActive: true,
  };

  form.innerHTML = `
    <div class="form-grid two">
      ${simpleInput("Nombre", "name", service.name, "text", "Lavado Premium")}
      ${simpleInput("Precio ARS", "price", service.price, "number", "12000")}
      ${simpleInput("Duracion min", "estimatedMinutes", service.estimatedMinutes, "number", "60")}
      ${simpleSelect("Categoria", "category", service.category, categoryLabels)}
      ${simpleInput("Orden", "sortOrder", service.sortOrder, "number", "1")}
      ${simpleSelect("Visible", "isActive", String(service.isActive), { true: "Activo", false: "Inactivo" })}
      <div class="field md:col-span-2">
        <label for="description">Descripcion</label>
        <textarea id="description" name="description" placeholder="Descripcion comercial">${escapeHtml(service.description || "")}</textarea>
      </div>
    </div>
    <div class="booking-actions">
      <button class="primary-action" type="submit">${editing ? "Guardar cambios" : "Crear servicio"}</button>
      ${editing ? `<button class="plain-button" type="button" data-action="cancel-service-edit">Cancelar</button>` : ""}
    </div>
  `;
}

function renderServicesAdminList() {
  const list = document.getElementById("services-admin-list");
  if (!list) return;

  const services = [...state.services].sort((a, b) => Number(a.sortOrder) - Number(b.sortOrder));
  list.innerHTML = services
    .map((service) => `
      <article class="stack-card">
        <div class="card-head">
          <div>
            <h4>${escapeHtml(service.name)}</h4>
            <div class="card-meta">
              <span>${categoryLabels[service.category]}</span>
              <span>${service.estimatedMinutes} min</span>
              <span>${formatMoney(service.price)}</span>
            </div>
          </div>
          <span class="badge ${service.isActive ? "green" : "red"}">${service.isActive ? "Activo" : "Inactivo"}</span>
        </div>
        <p class="muted mt-3">${escapeHtml(service.description)}</p>
        <div class="row-actions">
          <button class="plain-button" type="button" data-action="edit-service" data-id="${service.id}">Editar</button>
          <button class="warning-button" type="button" data-action="toggle-service" data-id="${service.id}">${service.isActive ? "Desactivar" : "Activar"}</button>
          <button class="danger-button" type="button" data-action="delete-service" data-id="${service.id}">Eliminar</button>
        </div>
      </article>
    `)
    .join("");
}

function saveService(form) {
  if (!isAdmin()) {
    showToast("Solo admin puede gestionar servicios.");
    return;
  }

  const now = nowIso();
  const payload = {
    name: String(form.get("name") || "").trim(),
    description: String(form.get("description") || "").trim(),
    price: Number(form.get("price") || 0),
    estimatedMinutes: Number(form.get("estimatedMinutes") || 60),
    category: String(form.get("category") || "wash"),
    isActive: String(form.get("isActive")) === "true",
    sortOrder: Number(form.get("sortOrder") || state.services.length + 1),
    updatedAt: now,
  };

  if (!payload.name || payload.price <= 0) {
    showToast("Completa nombre y precio del servicio.");
    return;
  }

  if (ui.editingServiceId) {
    const existing = state.services.find((item) => item.id === ui.editingServiceId);
    Object.assign(existing, payload);
    ui.editingServiceId = null;
    showToast("Servicio actualizado.");
  } else {
    state.services.push({
      id: makeId("srv"),
      ...payload,
      createdAt: now,
    });
    showToast("Servicio creado.");
  }

  saveStore();
  syncAdminStateToSupabase();
  renderAll();
}

function toggleService(id) {
  const service = state.services.find((item) => item.id === id);
  if (!service) return;
  service.isActive = !service.isActive;
  service.updatedAt = nowIso();
  saveStore();
  syncAdminStateToSupabase();
  showToast(service.isActive ? "Servicio activado." : "Servicio desactivado.");
  renderAll();
}

function deleteService(id) {
  if (!confirm("Eliminar servicio? Los turnos historicos conservan nombre y precio.")) return;
  state.services = state.services.filter((item) => item.id !== id);
  saveStore();
  deleteSupabaseRow("services", "id", id);
  syncAdminStateToSupabase();
  showToast("Servicio eliminado.");
  renderAll();
}

function renderFinance() {
  renderFinanceKpis();
  renderExpenseForm();
  renderExpenseList();
}

function renderFinanceKpis() {
  const income = state.appointments
    .filter((item) => item.status === "done")
    .reduce((sum, item) => sum + Number(item.servicePrice || 0), 0);
  const expenses = state.expenses.reduce((sum, item) => sum + Number(item.amount || 0), 0);
  const net = income - expenses;
  const doneCount = state.appointments.filter((item) => item.status === "done").length;

  setHtml("finance-kpis", `
    ${kpi("Ingresos", formatMoney(income))}
    ${kpi("Egresos", formatMoney(expenses))}
    ${kpi("Ganancia neta", formatMoney(net))}
    ${kpi("Servicios realizados", doneCount)}
  `);
}

function renderExpenseForm() {
  const form = document.getElementById("expense-form");
  if (!form) return;

  form.innerHTML = `
    <div class="form-grid two">
      ${simpleInput("Concepto", "title", "", "text", "Ej: Microfibras")}
      ${simpleInput("Monto ARS", "amount", "", "number", "15000")}
      ${simpleSelect("Categoria", "category", "supplies", {
        supplies: "Insumos",
        rent: "Alquiler",
        salary: "Sueldos",
        maintenance: "Mantenimiento",
        marketing: "Marketing",
        other: "Otros",
      })}
      ${simpleInput("Fecha", "expenseDate", dateInputValue(0), "date", "")}
      <div class="field md:col-span-2">
        <label for="notes">Notas</label>
        <textarea id="notes" name="notes" placeholder="Detalle opcional"></textarea>
      </div>
    </div>
    <div class="booking-actions">
      <button class="primary-action" type="submit">Registrar egreso</button>
    </div>
  `;
}

function renderExpenseList() {
  const list = document.getElementById("expense-list");
  if (!list) return;

  const expenses = [...state.expenses].sort((a, b) => new Date(b.expenseDate) - new Date(a.expenseDate));
  if (!expenses.length) {
    list.innerHTML = `<div class="empty-state">No hay egresos cargados.</div>`;
    return;
  }

  list.innerHTML = expenses
    .map((expense) => `
      <article class="stack-card">
        <div class="card-head">
          <div>
            <h4>${escapeHtml(expense.title)}</h4>
            <div class="card-meta">
              <span>${formatDate(expense.expenseDate)}</span>
              <span>${escapeHtml(expense.category)}</span>
            </div>
          </div>
          <strong>${formatMoney(expense.amount)}</strong>
        </div>
        ${expense.notes ? `<p class="muted mt-3">${escapeHtml(expense.notes)}</p>` : ""}
        <div class="row-actions">
          <button class="danger-button" type="button" data-action="delete-expense" data-id="${expense.id}">Eliminar</button>
        </div>
      </article>
    `)
    .join("");
}

function saveExpense(form) {
  if (!isAdmin()) {
    showToast("Solo admin puede cargar egresos.");
    return;
  }

  const title = String(form.get("title") || "").trim();
  const amount = Number(form.get("amount") || 0);

  if (!title || amount <= 0) {
    showToast("Completa concepto y monto.");
    return;
  }

  const now = nowIso();
  state.expenses.push({
    id: makeId("exp"),
    title,
    amount,
    category: String(form.get("category") || "other"),
    expenseDate: toIsoFromInput(String(form.get("expenseDate") || dateInputValue(0)), "12:00"),
    notes: String(form.get("notes") || "").trim() || null,
    createdBy: currentUser().uid,
    createdAt: now,
    updatedAt: now,
  });

  saveStore();
  syncAdminStateToSupabase();
  showToast("Egreso registrado.");
  renderAll();
}

function deleteExpense(id) {
  state.expenses = state.expenses.filter((item) => item.id !== id);
  saveStore();
  deleteSupabaseRow("expenses", "id", id);
  syncAdminStateToSupabase();
  showToast("Egreso eliminado.");
  renderAll();
}

function renderSettings() {
  const form = document.getElementById("settings-form");
  if (!form) return;

  form.innerHTML = `
    <div class="form-grid two">
      ${simpleInput("Nombre del negocio", "businessName", state.settings.businessName, "text", "A Todo Brillo")}
      ${simpleInput("Provincia", "province", state.settings.province, "text", "Mendoza")}
      ${simpleInput("Moneda", "currency", state.settings.currency, "text", "ARS")}
      ${simpleInput("Locale", "locale", state.settings.locale, "text", "es-AR")}
      ${simpleInput("Zona horaria", "timezone", state.settings.timezone, "text", "America/Argentina/Mendoza")}
      ${simpleSelect("Premio Club de Brillo", "loyaltyTargetServices", String(state.settings.loyaltyTargetServices), Object.fromEntries(allowedTargets.map((target) => [target, `${target} lavados`])))}
    </div>
    <div class="booking-actions">
      <button class="primary-action" type="submit">Guardar configuracion</button>
    </div>
  `;
}

function saveSettings(form) {
  if (!isAdmin()) {
    showToast("Solo admin puede cambiar configuracion.");
    return;
  }

  const target = Number(form.get("loyaltyTargetServices"));
  if (!allowedTargets.includes(target)) {
    showToast("El premio solo puede ser 5, 6, 7, 8, 9 o 10 lavados.");
    return;
  }

  Object.assign(state.settings, {
    businessName: String(form.get("businessName") || "A Todo Brillo").trim(),
    province: String(form.get("province") || "Mendoza").trim(),
    currency: String(form.get("currency") || "ARS").trim().toUpperCase(),
    locale: String(form.get("locale") || "es-AR").trim(),
    timezone: String(form.get("timezone") || "America/Argentina/Mendoza").trim(),
    loyaltyTargetServices: target,
    updatedBy: currentUser().uid,
    updatedAt: nowIso(),
  });

  recalculateRewardFlags();
  saveStore();
  syncAdminStateToSupabase();
  showToast("Configuracion guardada.");
  renderAll();
}

function renderLoyalty() {
  renderClientLookupForm();
  renderClientClubCard();
  renderLoyaltyList();
}

function renderClientLookupForm() {
  const form = document.getElementById("client-lookup-form");
  if (!form) return;

  form.innerHTML = `
    <div class="form-grid">
      ${simpleInput("WhatsApp", "phone", ui.clientLookupPhone, "tel", "Ej: 261 555 1234")}
    </div>
    <div class="booking-actions">
      <button class="primary-action" type="submit">Consultar</button>
    </div>
  `;
}

function renderClientClubCard() {
  const container = document.getElementById("client-club-card");
  if (!container) return;

  const normalized = normalizePhone(ui.clientLookupPhone);
  const user = state.users.find((item) => item.normalizedPhone === normalized && item.role === "client");

  if (!ui.clientLookupPhone) {
    container.innerHTML = `<div class="empty-state mt-4">Ingresa un WhatsApp para consultar el progreso.</div>`;
    return;
  }

  if (!user) {
    container.innerHTML = `<div class="empty-state mt-4">No encontramos un cliente con ese WhatsApp.</div>`;
    return;
  }

  container.innerHTML = `<div class="mt-4">${renderClientCard(user, false)}</div>`;
}

function renderLoyaltyList() {
  const list = document.getElementById("loyalty-list");
  if (!list) return;

  const clients = state.users
    .filter((user) => user.role === "client")
    .sort((a, b) => b.loyaltyPoints - a.loyaltyPoints);

  if (!clients.length) {
    list.innerHTML = `<div class="empty-state">Todavia no hay clientes en el Club.</div>`;
    return;
  }

  list.innerHTML = clients.map((user) => renderClientCard(user, isAdmin())).join("");
}

function renderClientCard(user, showActions) {
  const target = state.settings.loyaltyTargetServices;
  const available = user.loyaltyPoints >= target || user.courtesyWashAvailable;
  const activePoints = Math.min(user.loyaltyPoints, target);

  return `
    <article class="client-card">
      <div class="card-head">
        <div>
          <h4>${escapeHtml(user.displayName)}</h4>
          <div class="card-meta">
            <span>${escapeHtml(user.vehicleName || "Sin vehiculo")}</span>
            <span>${escapeHtml(user.phone)}</span>
            <span>${user.lifetimeServices} servicios historicos</span>
          </div>
        </div>
        <span class="badge ${available ? "green" : "blue"}">${available ? "Premio disponible" : `${user.loyaltyPoints}/${target}`}</span>
      </div>
      <div class="stamps" aria-label="Sellos de fidelizacion">
        ${Array.from({ length: target }, (_, index) => `<span class="stamp ${index < activePoints ? "active" : ""}">${index + 1}</span>`).join("")}
      </div>
      ${showActions && available ? `
        <div class="row-actions">
          <button class="success-button" type="button" data-action="redeem-loyalty" data-id="${user.uid}">Registrar canje</button>
        </div>
      ` : ""}
    </article>
  `;
}

function redeemLoyalty(uid) {
  if (!isAdmin()) {
    showToast("Solo admin puede registrar canjes.");
    return;
  }

  const user = state.users.find((item) => item.uid === uid);
  if (!user) return;

  const target = state.settings.loyaltyTargetServices;
  if (user.loyaltyPoints < target && !user.courtesyWashAvailable) {
    showToast("El cliente todavia no tiene premio disponible.");
    return;
  }

  const now = nowIso();
  user.loyaltyPoints = 0;
  user.courtesyWashAvailable = false;
  user.updatedAt = now;

  state.loyaltyEvents.push({
    id: makeId("loy"),
    userUid: user.uid,
    appointmentId: null,
    type: "redeemed",
    points: -target,
    reason: "Lavado de cortesia",
    createdBy: currentUser().uid,
    createdAt: now,
  });

  saveStore();
  syncOperationalStateToSupabase();
  showToast("Canje registrado y puntos reiniciados.");
  renderAll();
}

function recalculateRewardFlags() {
  const target = state.settings.loyaltyTargetServices;
  state.users.forEach((user) => {
    if (user.role === "client") {
      user.courtesyWashAvailable = user.loyaltyPoints >= target;
      user.updatedAt = nowIso();
    }
  });
}

function applyRoleVisibility() {
  document.querySelectorAll(".admin-only").forEach((element) => {
    element.classList.toggle("hidden-by-role", !isAdmin());
  });

  document.querySelectorAll(".staff-admin-only").forEach((element) => {
    element.classList.toggle("hidden-by-role", !isStaffOrAdmin());
  });
}

function getActiveServices() {
  return [...state.services]
    .filter((service) => service.isActive)
    .sort((a, b) => Number(a.sortOrder) - Number(b.sortOrder));
}

function currentUser() {
  if (ui.staffProfile) {
    return {
      uid: ui.staffProfile.userId,
      role: ui.staffProfile.role,
      displayName: ui.staffProfile.displayName || ui.staffProfile.email,
    };
  }

  return roleUsers[ui.currentRole];
}

function isStaffOrAdmin() {
  return ["staff", "admin"].includes(ui.currentRole) && Boolean(ui.staffProfile || !supabaseClient);
}

function isAdmin() {
  return ui.currentRole === "admin" && Boolean(ui.staffProfile || !supabaseClient);
}

function kpi(label, value) {
  return `
    <div class="kpi">
      <span>${escapeHtml(label)}</span>
      <strong>${escapeHtml(value)}</strong>
    </div>
  `;
}

function simpleInput(label, name, value, type, placeholder) {
  return `
    <div class="field">
      <label for="${name}">${label}</label>
      <input id="${name}" name="${name}" type="${type}" value="${escapeAttr(value ?? "")}" placeholder="${escapeAttr(placeholder || "")}" />
    </div>
  `;
}

function simpleSelect(label, name, value, options) {
  return `
    <div class="field">
      <label for="${name}">${label}</label>
      <select id="${name}" name="${name}">
        ${Object.entries(options)
          .map(([optionValue, optionLabel]) => `<option value="${escapeAttr(optionValue)}" ${String(value) === String(optionValue) ? "selected" : ""}>${escapeHtml(optionLabel)}</option>`)
          .join("")}
      </select>
    </div>
  `;
}

function normalizePhone(value) {
  let digits = String(value || "").replace(/\D/g, "");
  if (!digits) return "";
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.startsWith("549")) return digits;
  if (digits.startsWith("54")) return `549${digits.slice(2).replace(/^9/, "")}`;
  digits = digits.replace(/^0+/, "");
  return `549${digits}`;
}

function formatMoney(value) {
  return new Intl.NumberFormat(safeLocale(), {
    style: "currency",
    currency: state.settings.currency || "ARS",
    maximumFractionDigits: 0,
  }).format(Number(value || 0));
}

function formatNumber(value) {
  return new Intl.NumberFormat(safeLocale()).format(Number(value || 0));
}

function formatDateTime(iso) {
  return new Intl.DateTimeFormat(safeLocale(), {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: state.settings.timezone || "America/Argentina/Mendoza",
  }).format(new Date(iso));
}

function formatDate(iso) {
  return new Intl.DateTimeFormat(safeLocale(), {
    dateStyle: "medium",
    timeZone: state.settings.timezone || "America/Argentina/Mendoza",
  }).format(new Date(iso));
}

function safeLocale() {
  return isValidLocale(state.settings?.locale) ? state.settings.locale : "es-AR";
}

function dateInputValue(offsetDays = 0) {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Argentina/Mendoza",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function toIsoFromInput(date, time) {
  return new Date(`${date}T${time || "12:00"}:00`).toISOString();
}

function isToday(iso) {
  return dateKey(iso) === dateInputValue(0);
}

function dateKey(iso) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: state.settings.timezone || "America/Argentina/Mendoza",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date(iso));
}

function nowIso() {
  return new Date().toISOString();
}

function makeId(prefix) {
  return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`;
}

function setHtml(id, html) {
  const element = document.getElementById(id);
  if (element) element.innerHTML = html;
}

function showToast(message) {
  const toast = document.getElementById("toast");
  if (!toast) return;

  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(ui.toastTimer);
  ui.toastTimer = setTimeout(() => toast.classList.remove("show"), 3200);
}

function refreshIcons() {
  if (window.lucide) window.lucide.createIcons();
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttr(value) {
  return escapeHtml(value);
}
