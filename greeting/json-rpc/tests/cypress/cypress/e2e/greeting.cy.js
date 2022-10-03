describe('greeting app', () => {
  beforeEach(() => {
    cy.visit('http://localhost:3000')
  })

  it('should have hello world message by default', () => {
    cy.get('p.greeting').should('have.text', 'Hello, World!')
  })
})
