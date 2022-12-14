describe("greeting app", () => {
  beforeEach(() => {
    cy.visit("http://localhost:3000");
  });

  it("should have hello alice message when Alice is typed", () => {
    cy.intercept("POST", "/", { fixture: "alice_result.json" }).as("api");
    cy.get("input#inputName").type("Alice");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, Alice!");
  });

  it("should have hello bob message when Bob is typed", () => {
    cy.intercept("POST", "/", { fixture: "bob_result.json" }).as("api");
    cy.get("input#inputName").type("Bob");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, Bob!");
  });

  it("should have hello world message by default", () => {
    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, World!");
  });

  it("should have hello world message when nothing is typed", () => {
    cy.intercept("POST", "/", { fixture: "world_result.json" }).as("api");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, World!");
  });

  it("should have hello world message when nothing is typed after a previous name", () => {
    cy.intercept("POST", "/", { fixture: "bob_result.json" }).as("api");
    cy.get("input#inputName").type("Bob");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.intercept("POST", "/", { fixture: "world_result.json" }).as("api");
    cy.get("input#inputName").type("{backspace}{backspace}{backspace}");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, World!");
  });

  it("should have hello world message when spaces are typed", () => {
    cy.intercept("POST", "/", { fixture: "bob_result.json" }).as("api");
    cy.get("input#inputName").type("Bob");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.intercept("POST", "/", { fixture: "world_result.json" }).as("api");
    cy.get("input#inputName").type("{backspace}{backspace}{backspace}  ");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("[data-testid=\"greeting-test\"]").should("have.text", "Hello, World!");
  });
});
