import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.search = this.debounce(this.search.bind(this), 300);
  }

  search(event) {
    const query = event.target.value.trim();
    const url = query
      ? `${this.element.action}?q=${encodeURIComponent(query)}`
      : this.element.action;

    fetch(url, {
      headers: { Accept: "application/json" },
    })
      .then((response) => response.json())
      .then((data) => {
        this.updateContacts(data.results);
      })
      .catch((error) => console.error("Erro na busca:", error));
  }

  updateContacts(results) {
    const contactsList = document.getElementById("contacts");
    if (!contactsList) {
      console.error("Elemento #contacts não encontrado!");
      return;
    }

    contactsList.innerHTML = "";

    results.forEach((contact) => {
      contactsList.innerHTML += this.contactTemplate(contact);
    });
  }

  contactTemplate(contact) {
    return `
      <li class="flex items-center gap-4" id="contact-${
        contact.id
      }" data-controller="load-lucid-icons load-flowbite">
        <div class="p-2.5 rounded-lg border-2 border-light-palette-p3 bg-light-palette-p4">
          <i data-lucide="user" class="w-5 stroke-dark-gray-palette-p3"></i>
        </div>
        <div class="mr-auto">
          <div class="flex items-center gap-1.5">
            <h2 class="typography-text-s-lh150 text-dark-gray-palette-p1">${
              contact.full_name || "Sem nome"
            }</h2>
            ${
              contact.email
                ? `
              <a href="mailto:${contact.email}" class="typography-text-r-lh150 text-dark-gray-palette-p4 flex items-center gap-0.5 hover:text-dark-gray-palette-p2">
                ${contact.email}
                <i data-lucide="arrow-up-right-square" class="w-3.5"></i>
              </a>`
                : ""
            }
          </div>
          <a href="tel:${
            contact.phone
          }" class="typography-sub-text-s-lh150 text-dark-gray-palette-p4 hover:text-dark-gray-palette-p3">${
      contact.phone || ""
    }</a>
        </div>
        <button id="dropdownContactBtn-${
          contact.id
        }" data-dropdown-toggle="dropdownContactOptions-${
      contact.id
    }" data-dropdown-placement="left-start" class="inline-flex items-center p-2 bg-white rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none dark:text-white focus:ring-gray-50 dark:bg-gray-800 dark:hover:bg-gray-700 dark:focus:ring-gray-600" type="button">
          <i data-lucide="more-vertical" class="stroke-dark-gray-palette-p3"></i>
        </button>
        <div id="dropdownContactOptions-${
          contact.id
        }" class="z-10 hidden left-16 bg-white divide-y divide-gray-100 rounded-lg shadow w-48 dark:bg-gray-700">
          <ul class="py-2 typography-text-m-lh150 text-dark-gray-palette-p3 dark:text-gray-200">
            <li>
              <a href="/accounts/${contact.account_id}/contacts/${
      contact.id
    }" class="flex items-center space-x-2 px-4 py-2 hover:bg-gray-100 hover:text-dark-gray-palette-p1 dark:hover:bg-gray-600 dark:hover:text-white">
                <i data-lucide="pencil"></i>
                <p>Editar</p>
              </a>
            </li>
            <li>
              <a href="/accounts/${contact.account_id}/contacts/${
      contact.id
    }" data-method="delete" data-confirm="Tem certeza que deseja excluir?" class="flex items-center space-x-2 px-4 py-2 hover:bg-gray-100 hover:text-dark-gray-palette-p1 dark:hover:bg-gray-600 dark:hover:text-white">
                <i data-lucide="trash"></i>
                <p>Excluir</p>
              </a>
            </li>
          </ul>
        </div>
      </li>
      <div class="w-full h-0.5 bg-light-palette-p3 last:hidden"></div>
    `;
  }

  debounce(func, delay) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => func(...args), delay);
    };
  }
}
