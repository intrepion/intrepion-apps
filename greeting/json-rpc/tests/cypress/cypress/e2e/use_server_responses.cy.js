describe("greeting app", () => {
  beforeEach(() => {
    cy.visit("http://localhost:3000");
  });

  it("should have hello world message by default", () => {
    cy.get("p.greeting").should("have.text", "Hello, World!");
  });

  it("should have hello alice message when Alice is typed", () => {
    cy.intercept("POST", "/api").as("api");
    cy.get("input#inputName").type("Alice");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("p.greeting").should("have.text", "Hello, Alice!");
  });

  it("should have hello bob message when Bob is typed", () => {
    cy.intercept("POST", "/api").as("api");
    cy.get("input#inputName").type("Bob");
    cy.get("button#submitName").click();

    cy.wait("@api");

    cy.get("p.greeting").should("have.text", "Hello, Bob!");
  });
});
