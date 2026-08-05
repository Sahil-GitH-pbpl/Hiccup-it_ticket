document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("grievance-form");
  const category = document.getElementById("category");
  const staffField = document.getElementById("staff-field");
  const staffSearch = document.getElementById("staff-search");
  const staffSuggestions = document.getElementById("staff-suggestions");
  const selectedStaff = document.getElementById("selected-staff");
  const staffHiddenInputs = document.getElementById("staff-hidden-inputs");
  const staffDataNode = document.getElementById("staff-data");
  const preselectedStaffDataNode = document.getElementById("preselected-staff-data");
  const description = document.getElementById("description");
  const descriptionCount = document.getElementById("description-count");
  const expectedResolution = document.getElementById("expected-resolution");
  const evidence = document.getElementById("evidence");
  const selectedFileName = document.getElementById("selected-file-name");

  const allowedExtensions = [".jpg", ".jpeg", ".png", ".pdf", ".doc", ".docx"];
  const maxFileSize = 10 * 1024 * 1024;
  const staffRequiredCategories = new Set([
    "TL, Manager, Colleagues, Supervisor",
    "Other Staff Related",
    "Harassment, Discrimination",
  ]);
  const staffList = JSON.parse(staffDataNode?.textContent || "[]");
  const selectedStaffIds = new Set(JSON.parse(preselectedStaffDataNode?.textContent || "[]").map(String));

  function getErrorNode(fieldName) {
    return document.querySelector(`[data-error-for="${fieldName}"]`);
  }

  function setError(fieldName, message) {
    const node = getErrorNode(fieldName);
    if (node) node.textContent = message || "";
    const field = node ? node.closest(".grievance-field") : null;
    if (field) field.classList.toggle("has-error", Boolean(message));
  }

  function clearError(fieldName) {
    setError(fieldName, "");
  }

  function toggleStaffField() {
    const shouldShow = staffRequiredCategories.has(category.value);
    staffField.classList.toggle("grievance-field--hidden", !shouldShow);
    if (!shouldShow) {
      staffSearch.value = "";
      selectedStaffIds.clear();
      renderSelectedStaff();
      hideSuggestions();
      clearError("staff_ids");
    }
  }

  function updateDescriptionCounter() {
    descriptionCount.textContent = String(description.value.trim().length);
  }

  function getFilteredStaff(query) {
    const normalizedQuery = query.trim().toLowerCase();
    if (!normalizedQuery) return [];
    return staffList
      .filter((staff) => !selectedStaffIds.has(String(staff.id)))
      .filter((staff) => `${staff.name} ${staff.designation}`.toLowerCase().includes(normalizedQuery))
      .slice(0, 8);
  }

  function hideSuggestions() {
    staffSuggestions.classList.add("hidden");
    staffSuggestions.innerHTML = "";
  }

  function renderSuggestions() {
    const results = getFilteredStaff(staffSearch.value);
    staffSuggestions.innerHTML = "";
    if (!staffSearch.value.trim()) {
      hideSuggestions();
      return;
    }
    if (!results.length) {
      staffSuggestions.innerHTML = '<div class="staff-empty">No staff found</div>';
      staffSuggestions.classList.remove("hidden");
      return;
    }
    results.forEach((staff) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "staff-suggestion";
      button.innerHTML = `<strong>${staff.name}</strong><span>${staff.designation || ""}</span>`;
      button.addEventListener("click", () => {
        selectedStaffIds.add(String(staff.id));
        staffSearch.value = "";
        renderSelectedStaff();
        hideSuggestions();
        clearError("staff_ids");
        staffSearch.focus();
      });
      staffSuggestions.appendChild(button);
    });
    staffSuggestions.classList.remove("hidden");
  }

  function renderSelectedStaff() {
    selectedStaff.innerHTML = "";
    staffHiddenInputs.innerHTML = "";
    Array.from(selectedStaffIds).forEach((id) => {
      const staff = staffList.find((item) => String(item.id) === String(id));
      if (!staff) return;
      const chip = document.createElement("span");
      chip.className = "staff-chip";
      chip.innerHTML = `<span class="staff-chip__name" title="${staff.name}">${staff.name}</span><button type="button" aria-label="Remove ${staff.name}">&times;</button>`;
      chip.querySelector("button").addEventListener("click", () => {
        selectedStaffIds.delete(String(id));
        renderSelectedStaff();
        renderSuggestions();
      });
      selectedStaff.appendChild(chip);

      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "staff_ids";
      input.value = id;
      staffHiddenInputs.appendChild(input);
    });
  }

  function validateAttachment() {
    const file = evidence.files && evidence.files[0];
    if (!file) {
      selectedFileName.textContent = "No file selected";
      clearError("evidence");
      return true;
    }

    selectedFileName.textContent = file.name;
    const lowerName = file.name.toLowerCase();
    const isAllowed = allowedExtensions.some((extension) => lowerName.endsWith(extension));
    if (!isAllowed) {
      setError("evidence", "Attachment must be a JPG, PNG, PDF, DOC, or DOCX file.");
      return false;
    }
    if (file.size > maxFileSize) {
      setError("evidence", "Attachment size must be 10 MB or less.");
      return false;
    }
    clearError("evidence");
    return true;
  }

  function validateForm() {
    let isValid = true;
    const descriptionText = description.value.trim();
    const resolutionText = expectedResolution.value.trim();

    if (!category.value) {
      setError("category", "Please select grievance category.");
      isValid = false;
    } else {
      clearError("category");
    }

    if (staffRequiredCategories.has(category.value) && selectedStaffIds.size === 0) {
      setError("staff_ids", "Please select at least one staff member involved.");
      isValid = false;
    } else {
      clearError("staff_ids");
    }

    if (!descriptionText) {
      setError("description", "Please enter grievance description.");
      isValid = false;
    } else {
      clearError("description");
    }

    if (!resolutionText) {
      setError("expected_resolution", "Please enter expected resolution.");
      isValid = false;
    } else {
      clearError("expected_resolution");
    }

    if (!validateAttachment()) isValid = false;
    return isValid;
  }

  category.addEventListener("change", () => {
    toggleStaffField();
    clearError("category");
  });
  staffSearch.addEventListener("input", renderSuggestions);
  staffSearch.addEventListener("focus", renderSuggestions);
  document.addEventListener("click", (event) => {
    if (!event.target.closest("#staff-picker")) hideSuggestions();
  });
  description.addEventListener("input", () => {
    updateDescriptionCounter();
    if (description.value.trim()) clearError("description");
  });
  expectedResolution.addEventListener("input", () => clearError("expected_resolution"));
  evidence.addEventListener("change", validateAttachment);

  form.addEventListener("submit", (event) => {
    if (!validateForm()) {
      event.preventDefault();
      const firstError = form.querySelector(".has-error input, .has-error select, .has-error textarea");
      if (firstError) firstError.focus();
    }
  });

  toggleStaffField();
  renderSelectedStaff();
  updateDescriptionCounter();
  validateAttachment();

  if (window.grievanceSuccessMessage) {
    form.reset();
    selectedStaffIds.clear();
    renderSelectedStaff();
    toggleStaffField();
    updateDescriptionCounter();
    selectedFileName.textContent = "No file selected";

    if (window.Swal) {
      window.Swal.fire({
        icon: "success",
        title: "Submitted",
        text: window.grievanceSuccessMessage,
        confirmButtonColor: "#0db29c",
      });
    } else {
      window.alert(window.grievanceSuccessMessage);
    }
  }
});
